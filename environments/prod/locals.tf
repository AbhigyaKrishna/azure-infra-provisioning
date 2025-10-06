locals {
  environment = "prod"
  common_tags = merge(var.common_tags, {
    Project     = var.project_name
    Environment = local.environment
  })

  admin_username  = "azureuser"
  vm_count        = 3
  vm_size         = "Standard_Av2"
  bastion_vm_size = "Standard_B1s"

  ssh_key = file(var.ssh_key_file_path)
}
