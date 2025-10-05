output "application_gateway_id" {
  description = "The ID of the Application Gateway."
  value       = azurerm_application_gateway.main.id
}

output "application_gateway_name" {
  description = "The name of the Application Gateway."
  value       = azurerm_application_gateway.main.name
}

output "public_ip_address" {
  description = "The public IP address of the Application Gateway."
  value       = azurerm_public_ip.appgw_ip.ip_address
}

output "public_ip_fqdn" {
  description = "The FQDN of the public IP address."
  value       = azurerm_public_ip.appgw_ip.fqdn
}

output "backend_pool_id" {
  description = "The ID of the backend address pool."
  value       = azurerm_application_gateway.main.backend_address_pool[0].id
}

output "cert_password" {
  description = "Certificate password"
  value       = random_password.cert_password.result
  sensitive   = true
}
