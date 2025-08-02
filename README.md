# Security Monitoring Infrastructure Deployment Guide

This guide provides step-by-step instructions for deploying a complete security monitoring infrastructure using ELK Stack, Wazuh Manager, and Windows agents.

## Prerequisites

- AWS CLI configured with appropriate credentials and region
- Terraform used to deploy infrastructure into a segmented, VPC-contained environment
- Access to AWS SSM for instance management

## Architecture Overview

The deployment consists of three main components:
1. **ELK Stack Server** – Elasticsearch and Kibana for data storage and visualization
2. **Wazuh Manager** – Centralized log aggregation, threat detection, and agent coordination (SIEM functions)
3. **Windows Agent(s)** – Monitors endpoint activity using Sysmon and forwards logs to Wazuh for analysis

## Deployment Steps

### Step 1: Deploy ELK Server

1. Launch EC2 instance with ELK installation script in user data  
2. Wait for installation to complete (approximately 10–15 minutes)  
3. Verify ELK stack functionality:

    ```bash
    # SSH into ELK server
    aws ssm start-session --target ELK_INSTANCE_ID

    # Test Elasticsearch
    curl http://localhost:9200

    # Test Kibana
    curl -I http://localhost:5601
    # Expected response: HTTP/1.1 302 Found (redirect to Kibana interface)
    ```

### Step 2: Deploy Wazuh Manager

1. Launch EC2 instance with Wazuh installation script  
2. Wait for installation to complete (approximately 10–15 minutes)  
3. Connect to Wazuh Manager:

    ```bash
    aws ssm start-session --target WAZUH_MANAGER_INSTANCE_ID
    ```

4. Configure Filebeat integration:

    ```bash
    # Edit the Filebeat configuration script
    sudo nano /root/configure-filebeat.sh
    # Change: ELK_IP="REPLACE_ME" 
    # To: ELK_IP="10.2.0.XXX" (your ELK server private IP)

    # Execute the configuration script
    sudo /root/configure-filebeat.sh
    ```

5. Verify Wazuh services:

    ```bash
    sudo systemctl status wazuh-manager
    sudo /var/ossec/bin/wazuh-control status
    ```

### Step 3: Deploy Windows Agent(s)

1. Launch Windows EC2 instance with Wazuh agent installation script  
2. Wait for installation to complete (approximately 5–10 minutes)  
3. Connect via SSM:

    ```bash
    aws ssm start-session --target WINDOWS_INSTANCE_ID
    ```

4. Configure the agent:

    ```powershell
    # Update the configuration script with Wazuh Manager IP
    (Get-Content "C:\Users\Administrator\Desktop\configure-wazuh.ps1") -replace "ManagerIP = 'REPLACE_ME'", "ManagerIP = '10.2.0.XXX'" | Set-Content "C:\Users\Administrator\Desktop\configure-wazuh.ps1"

    # Execute the configuration script
    .\configure-wazuh.ps1
    ```

5. Verify services:

    ```powershell
    Get-Service -Name "WazuhSvc"
    Get-Service -Name "Sysmon64"
    ```

### Step 4: Verify End-to-End Data Flow

1. Retrieve ELK instance metadata (useful if IP not known from Terraform outputs):

    ```bash
    aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" \
        --query "Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Name'].Value|[0],InstanceType,PrivateIpAddress]" \
        --output table \
        --region REGION \
        --profile PROFILE_NAME
    ```

2. Establish port forwarding to access Kibana:

    ```bash
    aws ssm start-session \
        --target ELK_INSTANCE_ID \
        --document-name AWS-StartPortForwardingSession \
        --parameters '{"portNumber":["5601"],"localPortNumber":["5601"]}' \
        --region REGION \
        --profile PROFILE_NAME
    ```

3. Access Kibana interface:

   - Open browser and navigate to: `http://localhost:5601`

4. Verify data ingestion in Kibana:

   - Navigate to "Stack Management" → "Index Management"  
   - Look for indices with "wazuh-*" prefix  
   - Use "Discover" feature to search and analyze security data

5. Confirm agent connectivity:

    ```bash
    sudo /var/ossec/bin/agent_control -l
    # Should display connected Windows agent with "Active" status
    ```

6. Generate test events:

   - Create/delete files on Windows system  
   - Execute various commands to generate Sysmon events  
   - Verify events appear in Kibana Discover

## Troubleshooting

### No Data Appearing in Kibana

Check Filebeat service status:

```bash
# On Wazuh Manager
sudo systemctl status filebeat
sudo journalctl -u filebeat -f

# Check Filebeat logs for output errors
sudo cat /var/log/filebeat/filebeat.log | grep ERROR

# Verify data transmission to Elasticsearch
curl "http://ELK_SERVER_IP:9200/_cat/indices?v" | grep wazuh
```

### Windows Agent Connection Issues

Monitor agent logs:

```powershell
# On Windows system
Get-Content "C:\Program Files (x86)\ossec-agent\ossec.log" -Tail 20
```

Check Wazuh Manager logs:

```bash
# On Wazuh Manager
sudo tail -f /var/ossec/logs/ossec.log | grep "agent"
```

## Success Criteria

Deployment is successful when the following conditions are met:

- **ELK Server**: Kibana accessible via SSM-based port forwarding, no auth required due to local-only access  
- **Wazuh Manager**: Connected agents visible in agent list  
- **Windows Agent**: Wazuh and Sysmon services running with "Active" status  
- **Data Flow**: Wazuh indices present in Elasticsearch  
- **Visualization**: Security events visible in Kibana Discover interface  

## Timeline Estimates

| Component               | Estimated Time                                   |
| ----------------------- | ------------------------------------------------ |
| ELK Server              | 10–15 minutes                                    |
| Wazuh Manager           | 15–20 minutes (including Filebeat configuration) |
| Windows Agent           | 5–10 minutes per agent                           |
| End-to-end verification | 5–10 minutes                                     |
| **Total**               | **45–60 minutes**                                |

## Security Considerations

- Ensure components are deployed in isolated subnets with restricted security groups and no public IPs  
- Verify security group configurations allow only necessary traffic  
- Port forwarding through AWS SSM Session Manager is required to access Kibana from your local machine  
- Monitor for successful agent registration and data flow  
- Regularly review security events and alerts in Kibana  

## Additional Notes

- All components should be deployed in the same VPC for optimal connectivity  
- Private IP addresses are used for internal communication  
- Port forwarding is required to access Kibana from external networks  
- Default credentials are not required for the OSS ELK stack configuration
