variable "public_subnet_id" {
    type = string
}

variable "private_subnet_id" {
    type = string
}

variable "private_monitor_subnet_id" {
    type = string
}

variable "wazuh_sg_id" {
    type = string
}

variable "windows_sg_id" {
    type = string
}

variable "bastion_windows_sg_id" {
    type = string
}

variable "elk_sg_id" {
    type = string
}

variable "ssm_instance_profile_name" {
    type = string
}

variable "wazuh_ami_id" {
    type = string
    description = "The AMI ID for the wazuh manager"
}

variable "windows_ami_id" {
    type = string
    description = "The AMI ID for the Windows endpoint"
}

variable "elk_ami_id" {
    type = string
    description = "The AMI ID for the elk endpoint"
}

variable "windows_key_name" {
    type = string
    description = "key pair for bastion host"
}