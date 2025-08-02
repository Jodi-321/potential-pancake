output "wazuh_instance_id" {
    value = aws_instance.wazuh_manager.id
}


output "windows_instance_id" {
    value = aws_instance.windows_endpoint.id
}

output "elk_instance_id" {
    value = aws_instance.elk_stack.id
}

output "bastion_windows_instance_id" {
    value = aws_instance.bastion_windows_endpoint.id
}

output "bastion_eip_id" {
  value = aws_eip.bastion_eip.id
}

output "bastion_eip_ip" {
  value = aws_eip.bastion_eip.public_ip
}

