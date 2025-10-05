output "vm_ids" {
  description = "The IDs of the virtual machines."
  value       = azurerm_linux_virtual_machine.main[*].id
}

output "vm_names" {
  description = "The names of the virtual machines."
  value       = azurerm_linux_virtual_machine.main[*].name
}

output "vm_private_ips" {
  description = "The private IP addresses of the virtual machines."
  value       = azurerm_linux_virtual_machine.main[*].private_ip_address
}

output "network_interface_ids" {
  description = "The IDs of the network interfaces."
  value       = azurerm_network_interface.vm[*].id
}
