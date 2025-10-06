terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstate202510"
    container_name       = "tfstate"
    key                  = "${local.environment}.terraform.tfstate"
  }
}
