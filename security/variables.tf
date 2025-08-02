variable "vpc_id" {
    description = "VPC ID where security groups will be created"
    type = string
}

variable "my_public_ip_id" {
    description = "Public IP for RDP only"
    type = string
}

variable "bastion_eip_ip" {
    type = string
}