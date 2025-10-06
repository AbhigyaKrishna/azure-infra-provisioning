locals {
  environment = "test"
  common_tags = merge(var.common_tags, {
    Project     = var.project_name
    Environment = local.environment
  })

  admin_username = "azureuser"
  vm_count = 1
  vm_size  = "Standard_Av2"

  ssh_key = file(var.ssh_key_file_path)
}
