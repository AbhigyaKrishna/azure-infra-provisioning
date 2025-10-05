resource "azurerm_public_ip" "appgw_ip" {
  name                = "${var.project_name}-${var.environment}-appgw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-appgw-pip"
    Environment = var.environment
  })
}

resource "azurerm_key_vault" "appgw_cert" {
  name                       = "${var.project_name}-${var.environment}-kv"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    certificate_permissions = [
      "Create",
      "Delete",
      "Get",
      "List",
      "Import",
      "Update",
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
    ]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-kv"
    Environment = var.environment
  })
}

resource "random_password" "cert_password" {
  length  = 16
  special = true
}

resource "null_resource" "generate_cert" {
  provisioner "local-exec" {
    command = <<-EOT
      openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/${var.project_name}-${var.environment}-appgw.key -out /tmp/${var.project_name}-${var.environment}-appgw.crt -days 365 -nodes -subj "/CN=${azurerm_public_ip.appgw_ip.domain_name_label}.${var.location}.cloudapp.azure.com"
      openssl pkcs12 -export -out /tmp/${var.project_name}-${var.environment}-appgw.pfx -inkey /tmp/${var.project_name}-${var.environment}-appgw.key -in /tmp/${var.project_name}-${var.environment}-appgw.crt -passout pass:${random_password.cert_password.result}
    EOT
  }
}

resource "azurerm_application_gateway" "main" {
  name                = "${var.project_name}-${var.environment}-appgw"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw-ipcfg"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw_ip.id
  }

  backend_address_pool {
    name         = "backend-pool"
    ip_addresses = var.backend_ips
  }

  backend_http_settings {
    name                                = "https-backend-cfg"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 60
    pick_host_name_from_backend_address = false

    probe_name = "https-health-probe"
  }

  backend_http_settings {
    name                                = "http-backend-cfg"
    cookie_based_affinity               = "Disabled"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 60
    pick_host_name_from_backend_address = false

    probe_name = "http-health-probe"
  }

  probe {
    name                                      = "https-health-probe"
    protocol                                  = "Https"
    host                                      = "localhost"
    path                                      = "/health"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false

    match {
      status_code = ["200-399"]
    }
  }

  probe {
    name                                      = "http-health-probe"
    protocol                                  = "Http"
    host                                      = "localhost"
    path                                      = "/health"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false

    match {
      status_code = ["200-399"]
    }
  }

  ssl_certificate {
    name     = "appgw-ssl-cert"
    data     = filebase64("/tmp/${var.project_name}-${var.environment}-appgw.pfx")
    password = random_password.cert_password.result
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "https-port"
    protocol                       = "Https"
    ssl_certificate_name           = "appgw-ssl-cert"
    require_sni                    = false
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
    require_sni                    = false
  }

  redirect_configuration {
    name                 = "http-to-https-redirect"
    redirect_type        = "Permanent"
    target_listener_name = "https-listener"
    include_path         = true
    include_query_string = true
  }

  request_routing_rule {
    name                      = "https-routing-rule"
    rule_type                 = "Basic"
    http_listener_name        = "https-listener"
    backend_address_pool_name = "backend-pool"
    priority                  = 100
  }

  request_routing_rule {
    name                        = "http-routing-rule"
    rule_type                   = "Basic"
    http_listener_name          = "http-listener"
    redirect_configuration_name = "http-to-https-redirect"
    priority                    = 110
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-appgw"
    Environment = var.environment
  })

  depends_on = [null_resource.generate_cert, azurerm_public_ip.appgw_ip]
}
