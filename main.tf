module "network" {
    source = "./network"
    my_public_ip_id = var.my_public_ip_id
    bastion_windows_instance_id = module.instances.bastion_windows_instance_id
}
module "security" {
  source = "./security"
  vpc_id = module.network.vpc_id
  my_public_ip_id = var.my_public_ip_id
  bastion_eip_ip = module.instances.bastion_eip_ip
}
module "iam" {
  source = "./iam"
}
module "instances" {
  source = "./instances"
  public_subnet_id = module.network.public_subnet_id
  private_subnet_id = module.network.private_subnet_id
  private_monitor_subnet_id = module.network.private_monitor_subnet_id
  wazuh_sg_id = module.security.wazuh_sg_id
  windows_sg_id = module.security.windows_sg_id
  bastion_windows_sg_id = module.security.bastion_windows_sg_id
  elk_sg_id = module.security.elk_sg_id
  ssm_instance_profile_name = module.iam.ssm_instance_profile_name
  wazuh_ami_id = var.wazuh_ami_id
  elk_ami_id = var.elk_ami_id
  windows_ami_id = var.windows_ami_id
  windows_key_name = module.security.windows_key_name
}

provider "aws" {
  region  = "us-east-1"
  profile = var.profile_name
}

