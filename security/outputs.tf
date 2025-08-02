output "wazuh_sg_id" {
    value = aws_security_group.wazuh_sg.id
}

output "windows_sg_id" {
    value = aws_security_group.windows_sg.id
}

output "elk_sg_id" {
    value = aws_security_group.elk_sg.id
}

output "bastion_windows_sg_id" {
    value = aws_security_group.bastion_windows_sg.id
}

output "windows_key_name" {
    value = aws_key_pair.windows_key.key_name
}

output "windows_private_key_pem" {
    value = tls_private_key.windows_key.private_key_pem
    sensitive = true
}
