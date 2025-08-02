# Ransomware Detection and Response Infrastructure

## Project Overview

This project demonstrates the design and deployment of a comprehensive security monitoring infrastructure to detect and respond to ransomware threats using endpoint telemetry. Built as a graduate-level capstone project, it showcases enterprise-grade security architecture, infrastructure automation, and threat detection capabilities in a realistic financial services scenario.

## Fictional Scenario: IronLock Financial

**IronLock Financial** is a mid-sized digital banking and investment services firm that has become increasingly vulnerable to ransomware attacks due to:

- **Expanded Remote Work**: Post-pandemic shift to cloud-hosted infrastructure and remote access
- **High-Value Targets**: Sensitive financial data including client records and transaction logs
- **Limited Visibility**: Lack of fine-grained endpoint telemetry and behavioral monitoring
- **Detection Gaps**: Traditional antivirus solutions insufficient for modern ransomware techniques

### The Security Challenge

IronLock Financial currently lacks visibility into pre-encryption behaviors such as:
- File renaming patterns
- Process injection techniques
- Unauthorized registry modifications
- Anomalous process trees and DLL injection

Without enhanced behavioral monitoring, ransomware attacks may remain undetected until data is already encrypted and systems are inoperable, causing severe business disruption and eroding client trust.

## Solution Architecture

This project implements a telemetry-driven detection and response solution using open-source tools and AWS infrastructure:

### Core Components
- **ELK Stack Server** – Elasticsearch and Kibana for centralized data storage and visualization
- **Wazuh Manager** – SIEM functions including log aggregation, threat detection, and agent coordination
- **Windows Endpoints** – Monitored systems with Sysmon for detailed endpoint telemetry
- **Bastion Host** – Secure access point for infrastructure management

### Technical Skills Demonstrated
- **Infrastructure as Code**: Terraform for automated, repeatable deployments
- **Cloud Architecture**: Secure, segmented AWS VPC design with proper network isolation
- **Security Hardening**: Zero public IP architecture with SSM-based access
- **SIEM Architecture**: Understanding of security monitoring fundamentals transferable across cloud providers
- **Automation**: Bash and PowerShell scripts for service installation and configuration
- **Incident Response**: NIST-aligned procedures and custom detection rules

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    IronLock Financial                       │
│                   AWS VPC (10.2.0.0/24)                   │
├─────────────────────────────────────────────────────────────┤
│  Public Subnet (10.2.0.0/26)        │  Private Subnet      │
│  ┌─────────────────────┐            │  (10.2.0.64/26)     │
│  │   Bastion Host      │            │  ┌─────────────────┐ │
│  │   (Windows)         │            │  │ Windows         │ │
│  │   RDP Access        │◄───────────┼──┤ Endpoint        │ │
│  └─────────────────────┘            │  │ + Sysmon        │ │
│                                     │  │ + Wazuh Agent   │ │
│                                     │  └─────────────────┘ │
├─────────────────────────────────────┼─────────────────────┤
│  Monitoring Subnet (10.2.0.128/26) │                     │
│  ┌─────────────────────┐            │                     │
│  │   Wazuh Manager     │            │                     │
│  │   + Filebeat        │            │                     │
│  └─────────────────────┘            │                     │
│  ┌─────────────────────┐            │                     │
│  │   ELK Stack         │            │                     │
│  │   + Elasticsearch   │            │                     │
│  │   + Kibana          │            │                     │
│  └─────────────────────┘            │                     │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Basic understanding of networking and security concepts

## Quick Start

### 1. Infrastructure Deployment

```bash
# Clone the repository
git clone https://github.com/Jodi-321/potential-pancake.git
cd potential-pancake

# Deploy infrastructure
terraform init
terraform plan
terraform apply
```

### 2. Required Variables

Create a `terraform.tfvars` file with the following values:

```hcl
# terraform.tfvars
project_name     = "ironlock-security"  # Customize as needed
wazuh_ami_id     = "ami-xxxxxxxxx"      # Amazon Linux 2 AMI
elk_ami_id       = "ami-xxxxxxxxx"      # Ubuntu 20.04 AMI  
windows_ami_id   = "ami-xxxxxxxxx"      # Windows Server 2019/2022 AMI
my_public_ip_id  = "x.x.x.x/32"        # Your public IP for RDP access
```

### 3. Automated Installation Scripts

The Terraform deployment includes three user data scripts that automatically install and configure the security monitoring components:

#### **install-elk.sh** (ELK Stack Server)
This bash script runs on Ubuntu and performs the following actions:
- **Java Installation**: Installs OpenJDK 11 (required for Elasticsearch)
- **Repository Setup**: Adds Wazuh repository and GPG keys for package management
- **Elasticsearch Installation**: 
  - Installs open-source Elasticsearch
  - Creates data and log directories with proper permissions
  - Configures cluster settings (wazuh-cluster, single node)
  - Sets network binding to accept connections from VPC
- **Kibana Installation**:
  - Installs Open Distro Kibana
  - Removes security plugins for simplified access
  - Configures localhost-only access (requires port forwarding)
  - Connects to local Elasticsearch instance
- **Service Management**: Enables and starts both services automatically
- **Logging**: All installation output logged to `/var/log/install-elk.log`

#### **install-wazuh.sh** (Wazuh Manager)
This bash script runs on Amazon Linux 2 and performs:
- **System Updates**: Updates all packages to latest versions
- **Wazuh Repository**: Adds official Wazuh repository and GPG verification
- **Wazuh Manager Installation**: Installs and starts the core Wazuh manager service
- **Filebeat Preparation**: Creates a configuration script for later manual execution
  - Script templates Filebeat configuration for log forwarding
  - Requires manual IP address configuration (ELK server IP)
  - Configures JSON log parsing from `/var/ossec/logs/alerts/alerts.json`
  - Sets up Elasticsearch output for centralized log storage
- **Service Verification**: Confirms Wazuh manager is running properly

#### **install-windows-agent2.ps1** (Windows Endpoints)
This PowerShell script runs on Windows Server instances and installs:
- **Sysmon Installation**:
  - Downloads Microsoft Sysmon from official source
  - Applies SwiftOnSecurity configuration for comprehensive logging
  - Enables detailed process, network, and file system monitoring
  - Captures process creation, network connections, file modifications
- **Wazuh Agent Installation**:
  - Downloads and silently installs Wazuh agent MSI package
  - Creates desktop configuration script for manual IP setup
  - Configures agent to forward Windows Event Log and Sysmon data
- **Configuration Management**:
  - Generates `configure-wazuh.ps1` script on Administrator desktop
  - Requires manual Wazuh Manager IP configuration
  - Handles agent registration and service startup
- **Error Handling**: Comprehensive logging and error reporting throughout installation

### 4. Post-Deployment Configuration

After Terraform completes the infrastructure deployment (approximately 45-60 minutes), follow these steps to complete the security monitoring setup:

#### Step 1: Configure Wazuh-ELK Integration

1. **Get ELK Server IP Address**:
```bash
# Retrieve instance details
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=*elk*" "Name=instance-state-name,Values=running" \
    --query "Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,Tags[?Key=='Name'].Value|[0]]" \
    --output table
```

2. **Configure Filebeat on Wazuh Manager**:
```bash
# Connect to Wazuh Manager
aws ssm start-session --target WAZUH_INSTANCE_ID

# Edit configuration script with ELK IP
sudo nano /root/configure-filebeat.sh
# Change: ELK_IP="REPLACE_ME" 
# To: ELK_IP="10.2.0.XXX" (your ELK server private IP)

# Execute configuration
sudo /root/configure-filebeat.sh

# Verify services
sudo systemctl status wazuh-manager filebeat
```

#### Step 2: Configure Windows Agent

1. **Connect to Windows Endpoint**:
```bash
aws ssm start-session --target WINDOWS_INSTANCE_ID
```

2. **Configure Wazuh Agent**:
```powershell
# Navigate to desktop and edit configuration script
cd C:\Users\Administrator\Desktop
notepad configure-wazuh.ps1

# Replace 'REPLACE_ME' with Wazuh Manager IP (10.2.0.XXX)
# Save and execute
.\configure-wazuh.ps1

# Verify services
Get-Service -Name "WazuhSvc","Sysmon64"
```

#### Step 3: Access Kibana Dashboard

1. **Set up port forwarding**:
```bash
aws ssm start-session \
    --target ELK_INSTANCE_ID \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["5601"],"localPortNumber":["5601"]}'
```

2. **Access Kibana**: Open browser to `http://localhost:5601`

3. **Verify data flow**:
   - Navigate to "Stack Management" → "Index Management"
   - Look for indices with "wazuh-*" prefix
   - Use "Discover" to view security events

#### Step 4: Generate Test Events

Create test activities on the Windows endpoint to verify monitoring:

```powershell
# File operations
New-Item -Path "C:\temp\test.txt" -ItemType File
Remove-Item -Path "C:\temp\test.txt"

# Process execution
Get-Process
Start-Process notepad

# Registry operations  
New-Item -Path "HKCU:\Software\TestKey"
Remove-Item -Path "HKCU:\Software\TestKey"
```

## Verification Checklist

- [ ] **ELK Server**: Kibana accessible via port forwarding
- [ ] **Wazuh Manager**: Agent connectivity confirmed (`sudo /var/ossec/bin/agent_control -l`)
- [ ] **Windows Agent**: Wazuh and Sysmon services running
- [ ] **Data Flow**: Wazuh indices visible in Elasticsearch
- [ ] **Events**: Test activities appear in Kibana Discover

## Troubleshooting

### No Data in Kibana
```bash
# Check Filebeat status
sudo systemctl status filebeat
sudo journalctl -u filebeat -f

# Verify Elasticsearch connectivity
curl "http://ELK_IP:9200/_cat/indices?v" | grep wazuh
```

### Windows Agent Issues
```powershell
# Check agent logs
Get-Content "C:\Program Files (x86)\ossec-agent\ossec.log" -Tail 20

# Restart services if needed
Restart-Service WazuhSvc
```

## Project Outcomes

This infrastructure enables:

1. **Enhanced Threat Detection**: Real-time visibility into endpoint behaviors
2. **Incident Response**: Centralized logging and alerting capabilities  
3. **Compliance**: Audit trails and security event correlation
4. **Scalability**: Terraform automation for repeatable deployments
5. **Skills Development**: Hands-on experience with enterprise security tools

## Security Considerations

- All monitoring infrastructure deployed in private subnets with no public IP addresses
- Network segmentation with restrictive security groups
- Access only through AWS SSM Session Manager
- Encrypted data transmission between components
- Principle of least privilege for all IAM roles

## Project Context

This project was developed as a graduate-level capstone to demonstrate:

- **Infrastructure Automation**: Professional-grade Terraform skills
- **Security Architecture**: Understanding of defense-in-depth principles  
- **Cloud Engineering**: Secure, scalable AWS infrastructure design
- **SIEM Operations**: Practical experience with security monitoring tools
- **Scripting Proficiency**: Automation capabilities in multiple languages

The skills and architecture patterns demonstrated are transferable across cloud providers (AWS, Azure, GCP) and applicable to real-world enterprise security operations.

---

**Disclaimer**: This is a simulated environment for educational purposes. IronLock Financial is a fictional company created to provide realistic context for cybersecurity learning and demonstration.
