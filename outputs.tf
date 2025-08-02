output "vpc_id" {
    value = module.network.vpc_id
}

output "pulic_subnet_id" {
    value = module.network.public_subnet_id
}

output "private_subnet_id" {
    value = module.network.private_subnet_id
}

output "private_monitor_subnet_id" {
    value = module.network.private_monitor_subnet_id
}

output "wazuh_sg_id" {
    value = module.security.wazuh_sg_id
}

output "windows_sg_id" {
    value = module.security.windows_sg_id
}

output "elk_sg_id" {
    value = module.security.elk_sg_id
}

output "ssm_instance_profile_name" {
    value = module.iam.ssm_instance_profile_name
}

output "windows_key_name" {
    value = module.security.windows_key_name
}

output "windows_private_key_pem" {
  value = module.security.windows_private_key_pem
  sensitive = true
}