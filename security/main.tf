resource "aws_security_group" "wazuh_sg" {
    name = "wazuh-sg"
    description = "Security group for Wazuh server"
    vpc_id = var.vpc_id

    ingress {
        description = "Wazuh agent log forwarding"
        from_port = 1514
        to_port = 1514
        protocol = "tcp"
        cidr_blocks = ["10.2.0.0/24"]
    }

    ingress {
        description = "Wazuh agent enrollment"
        from_port = 1515
        to_port = 1515
        protocol = "tcp"
        cidr_blocks = ["10.2.0.0/24"]
    }

    ingress {
        description = "Wazuh agent registration"
        from_port = 55000
        to_port = 55000
        protocol = "tcp"
        cidr_blocks = ["10.2.0.0/24"]
    }

    egress {
        description = "Allow all outbound"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "wazuh-sg"
        Project = "capstone"
    }
}

resource "aws_security_group" "elk_sg" {
    name = "elk-sg"
    description = "Security group for ELK stack"
    vpc_id = var.vpc_id

    ingress {
        description = "Allow Filebeat to send logs to Elasticsearch"
        from_port = 9200
        to_port = 9200
        protocol = "tcp"
        cidr_blocks = ["10.2.0.0/24"]
    }

    ingress {
        description = "Allow kibana web UI from localhost"
        from_port = 5601
        to_port = 5601
        protocol = "tcp"
        cidr_blocks = ["127.0.0.1/32"]
    }

    egress {
        description = "Allow all outbound"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "elk-sg"
        Project = "capstone"
    }


}

resource "aws_security_group" "bastion_windows_sg" {
    name = "bastion_windows_sg"
    description = "Bastion host to connect to target windows"
    vpc_id = var.vpc_id

    ingress {
        from_port = 3389
        to_port = 3389
        protocol = "tcp"
        cidr_blocks = [var.my_public_ip_id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "bastion-windows-sg"
        Project = "capstone"
    }

}

resource "aws_security_group" "windows_sg" {
    name = "windows-sg"
    description = "Security group for Windows endpoint"
    vpc_id = var.vpc_id

    /*
    egress {
        description = "Allow all outbound"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    */

    ingress {
        from_port = 3389
        to_port = 3389
        protocol = "tcp"
        security_groups = [aws_security_group.bastion_windows_sg.id]
    }

    # Restricting outbound to only necessary ports/IP
    egress {
        description = "Allow outbound to Wazuh manager for log forwarding"
        from_port = 1514
        to_port = 1514
        protocol = "tcp"
        cidr_blocks = ["10.2.0.128/26"] # To the monitoring subnet only
    }

    egress {
        description = "Allow outbound to Wazuh manager for agent registration"
        from_port = 55000
        to_port = 55000
        protocol = "tcp"
        cidr_blocks = ["10.2.0.128/26"]
    }

    egress {
        description = "Allow outbount to Wazuh maanger for agent enrollment"
        from_port = 1515
        to_port = 1515
        protocol = "tcp"
        cidr_blocks = ["10.2.0.128/26"]
    }

    egress {
        from_port = 3389
        to_port = 3389
        protocol = "tcp"
        security_groups = [aws_security_group.bastion_windows_sg.id]
    }

    # Windows updates, Powershell modules, etc
    egress {
        description = "Allow outbound to internet via NAT"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "windows-sg"
        Project = "capstone"
    }
}