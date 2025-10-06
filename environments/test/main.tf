resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${local.environment}-rg"
  location = var.location

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${local.environment}-rg"
  })
}

module "network" {
  source              = "../../modules/network"
  project_name        = var.project_name
  environment         = local.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  common_tags         = local.common_tags
  address_space       = var.address_space
  private_subnet_cidr = var.private_subnet_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  bastion_subnet_cidr = var.bastion_subnet_cidr
}

module "compute" {
  source              = "../../modules/compute"
  project_name        = var.project_name
  environment         = local.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  common_tags         = local.common_tags
  vm_count            = local.vm_count
  vm_size             = local.vm_size
  admin_username      = local.admin_username
  ssh_public_key      = local.ssh_key
  subnet_id           = module.network.private_subnet_id
}

module "gateway" {
  source              = "../../modules/gateway"
  project_name        = var.project_name
  environment         = local.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  common_tags         = local.common_tags
  subnet_id           = module.network.public_subnet_id
  backend_ips         = module.compute.vm_private_ips
}

module "bastion" {
  source              = "../../modules/bastion"
  project_name        = var.project_name
  environment         = local.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  common_tags         = local.common_tags
  subnet_id           = module.network.bastion_subnet_id
  vm_size             = "Standard_B1s"
  admin_username      = local.admin_username
  ssh_public_key      = local.ssh_key
  allowed_ssh_cidr    = var.allowed_ssh_cidr
}
