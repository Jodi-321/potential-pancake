resource "aws_instance" "wazuh_manager" {
    ami = var.wazuh_ami_id
    instance_type = "t3.medium"
    subnet_id = var.private_monitor_subnet_id
    vpc_security_group_ids = [var.wazuh_sg_id]
    iam_instance_profile = var.ssm_instance_profile_name
    associate_public_ip_address = false

    root_block_device {
        volume_type = "gp3"
        volume_size = 50
        delete_on_termination = true
    }

    user_data = file("scripts/install-wazuh.sh")

    depends_on = [aws_instance.elk_stack]

    tags = {
        Name = "capstone-wazuh-manager"
        Role = "Wazuh"
        Project = "Capstone"
    }
}


resource "aws_instance" "elk_stack" {
    ami = var.elk_ami_id
    instance_type = "t3.large"
    subnet_id = var.private_monitor_subnet_id
    vpc_security_group_ids = [var.elk_sg_id]
    iam_instance_profile = var.ssm_instance_profile_name
    associate_public_ip_address = false

    root_block_device {
        volume_type = "gp3"
        volume_size = 50
        delete_on_termination = true
    }

    user_data = file("scripts/install-elk.sh")

    depends_on = [var.ssm_instance_profile_name]

    tags = {
        Name = "capstone-elk-stack"
        Role = "ELK"
        Project = "Capstone"
    }
}



resource "aws_instance" "windows_endpoint" {
    ami = var.windows_ami_id
    instance_type = "t3.large"
    subnet_id = var.private_subnet_id
    vpc_security_group_ids = [var.windows_sg_id]
    iam_instance_profile = var.ssm_instance_profile_name
    associate_public_ip_address = false

    root_block_device {
      volume_type = "gp3"
      volume_size = 50
      delete_on_termination = true
    }

    user_data = file("scripts/install-windows-agent2.ps1")

    depends_on = [aws_instance.wazuh_manager]

    tags = {
        Name = "capstone-windows-endpoint"
        Role = "Windows"
        Project = "Capstone"
    }

}

resource "aws_instance" "bastion_windows_endpoint" {
    ami = var.windows_ami_id
    instance_type = "t3.large"
    subnet_id = var.public_subnet_id
    vpc_security_group_ids = [var.bastion_windows_sg_id]
    iam_instance_profile = var.ssm_instance_profile_name
    associate_public_ip_address = false
    key_name = var.windows_key_name

    root_block_device {
        volume_type = "gp3"
        volume_size = 50
        delete_on_termination = true
    }

    lifecycle {
        ignore_changes = [vpc_security_group_ids]
    }


    tags = {
        Name = "capstone-bastion-windows-endpoint"
        Role = "Bastion"
        Project = "Capstone"
    }
}

resource "aws_eip" "bastion_eip" {
    
    tags = {
        Name = "BastionEIP"
        Project = "capstone"
    }
}
resource "aws_eip_association" "bastion_eip_assoc" {
    instance_id = aws_instance.bastion_windows_endpoint.id
    allocation_id = aws_eip.bastion_eip.id
} 
