#!/bin/bash
set -e

# Logging setup
exec > >(tee /var/log/install-elk.log|logger -t install-elk -s 2>/dev/console) 2>&1

echo "Starting ELK stack installation"

# Install Java (Required for Elasticsearch)
echo "Installing Java..."
apt-get update
apt-get install -y openjdk-11-jdk

# Verify Java installation
java -version

# Wazuh repo and GPG key
echo "Adding Wazuh repository..."
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor > wazuh.gpg
install -o root -g root -m 644 wazuh.gpg /etc/apt/trusted.gpg.d/
echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list


# Update packages
apt-get update

# Install Elasticsearch
echo "Installing Elasticsearch..."
apt-get install -y elasticsearch-oss

# Create and set permissions for data and logs directories
mkdir -p /var/lib/elasticsearch
mkdir -p /var/log/elasticsearch
chown -R elasticsearch:elasticsearch /var/lib/elasticsearch
chown -R elasticsearch:elasticsearch /var/log/elasticsearch
chmod 755 /var/lib/elasticsearch
chmod 755 /var/log/elasticsearch

# Configure Elasticsearch
echo "Configuring Elasticsearch..."
cat <<EOF > /etc/elasticsearch/elasticsearch.yml
cluster.name: wazuh-cluster
node.name: node-1
network.host: 0.0.0.0
http.port: 9200
discovery.seed_hosts: ["127.0.0.1"]
cluster.initial_master_nodes: ["node-1"]
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
EOF

# Set proper permissions
chown root:elasticsearch /etc/elasticsearch/elasticsearch.yml
chmod 660 /etc/elasticsearch/elasticsearch.yml

# Start Elasticsearch
echo "Starting Elasticsearch..."
systemctl daemon-reload
systemctl enable elasticsearch
systemctl start elasticsearch

# Install Kibana
echo "Installing Kibana..."
apt-get install -y opendistroforelasticsearch-kibana

# Configure Kibana
echo "Configuring Kibana..."
cat <<EOF > /etc/kibana/kibana.yml
server.host: "127.0.0.1"
server.port: 5601
elasticsearch.hosts: ["http://localhost:9200"]
EOF

# Start Kibana
echo "Starting Kibana..."
systemctl enable kibana
systemctl start kibana

# After installing Kibana, remove security plugin and configure basic access
/usr/share/kibana/bin/kibana-plugin remove opendistroSecurityKibana --allow-root
echo 'server.host: "127.0.0.1"' > /etc/kibana/kibana.yml
echo 'server.port: 5601' >> /etc/kibana/kibana.yml
echo 'elasticsearch.hosts: ["http://localhost:9200"]' >> /etc/kibana/kibana.yml
systemctl restart kibana

# Final status check
echo "Checking service status..."
systemctl status elasticsearch --no-pager
systemctl status kibana --no-pager
echo "ELK stack installed successfully!"
echo "Elasticsearch: http://localhost:9200"
echo "Kibana: http://localhost:5601"
echo ""
echo "Next steps:"
echo "1. Access Kibana at http://localhost:5601"
echo "2. Configure Wazuh Filebeat integration"
echo "3. Set up dashboards for Wazuh data"
