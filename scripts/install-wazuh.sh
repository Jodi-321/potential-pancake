#!/bin/bash

#this script installs Wazuh and preloads Filebeat config


exec > >(tee /var/log/wazuh_install.log|logger -t user-data -s 2>/dev/console) 2>&1

set -eux

# Update system
yum update -y

# Add Wazuh GPG key and repo
cat > /etc/yum.repos.d/wazuh.repo <<EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=Wazuh repository
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF

# Install Wazuh manager
yum install -y wazuh-manager

# Enable and start Wazuh manager
systemctl daemon-reexec
systemctl enable wazuh-manager
systemctl start wazuh-manager

#confirm service is running
systemctl status wazuh-manager || true

# Create manual run script to configure Filebeat after ELK is up
cat <<'EOF' > /root/configure-filebeat.sh
#!/bin/bash
set -eux

# !!! EDIT BEFORE RUNNING !!!
ELK_IP="REPLACE_ME"

if [ "$ELK_IP" = "REPLACE_ME" ]; then
    echo "You need to edit ELK_IP in this script before running."
    exit 1
fi

# Add Wazuh repo
cat > /etc/yum.repos.d/wazuh.repo <<REPO
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=Wazuh repository
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
REPO

# Install Filebeat
yum install -y filebeat

# Enable wazuh module (optional but safe)
filebeat modules enable wazuh || true

# Configure Filebeat
cat <<CONF > /etc/filebeat/filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/ossec/logs/alerts/alerts.json

output.elasticsearch:
  hosts: ["http://$ELK_IP:9200"]
CONF

# Start Filebeat
systemctl enable filebeat
systemctl start filebeat

echo " Filebeat configured to forward Wazuh alerts to $ELK_IP"
EOF

chmod +x /root/configure-filebeat.sh