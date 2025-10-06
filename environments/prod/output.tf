output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = module.network.vnet_id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = module.network.vnet_name
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.network.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = module.network.private_subnet_id
}

output "vm_ids" {
  description = "IDs of the deployed VMs"
  value       = module.compute.vm_ids
}

output "vm_names" {
  description = "Names of the deployed VMs"
  value       = module.compute.vm_names
}

output "vm_private_ips" {
  description = "Private IP addresses of the VMs"
  value       = module.compute.vm_private_ips
}

output "app_gateway_public_ip" {
  description = "Public IP of the Application Gateway"
  value       = module.gateway.public_ip_address
}

output "app_gateway_fqdn" {
  description = "FQDN of the Application Gateway"
  value       = module.gateway.public_ip_fqdn
}

output "app_gateway_url" {
  description = "Full HTTPS URL to access the application"
  value       = "https://${module.gateway.public_ip_fqdn}"
}

output "application_endpoints" {
  description = "Application access endpoints"
  value = {
    https_url = "https://${module.gateway.public_ip_fqdn}"
    public_ip = module.gateway.public_ip_address
  }
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = module.bastion.bastion_public_ip
}

output "bastion_vm_name" {
  description = "Name of the bastion virtual machine"
  value       = module.bastion.bastion_vm_name
}

output "bastion_private_ip" {
  description = "Private IP address of the bastion host"
  value       = module.bastion.bastion_private_ip
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    environment  = local.environment
    vm_count     = local.vm_count
    location     = var.location
    project_name = var.project_name
  }
}
