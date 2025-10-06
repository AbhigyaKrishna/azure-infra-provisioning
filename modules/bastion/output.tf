output "bastion_public_ip" {
  description = "The public IP address of the bastion host."
  value       = azurerm_public_ip.bastion.ip_address
}

output "bastion_vm_id" {
  description = "The ID of the bastion virtual machine."
  value       = azurerm_linux_virtual_machine.bastion.id
}

output "bastion_vm_name" {
  description = "The name of the bastion virtual machine."
  value       = azurerm_linux_virtual_machine.bastion.name
}

output "bastion_private_ip" {
  description = "The private IP address of the bastion host."
  value       = azurerm_linux_virtual_machine.bastion.private_ip_address
}

output "bastion_nic_id" {
  description = "The ID of the bastion network interface."
  value       = azurerm_network_interface.bastion.id
}
