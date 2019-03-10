# Configure the Azure Provider
# Use az login to autheticate with azure
provider "azurerm" {}

# Initilize Terraform to use remote backend \
# run : terraform init -backend-config="../backend.tfvars"
terraform {
  backend "azurerm" {
    key = "backend/backend.tfstate"
  }
}

resource "azurerm_resource_group" "backend" {
  name     = "${var.backend_resource_group_name}"
  location = "${var.default_resource_group_location}"
}

resource "azurerm_storage_account" "backend" {
  name                     = "tfstate2462134t"
  resource_group_name      = "${azurerm_resource_group.backend.name}"
  location                 = "${azurerm_resource_group.backend.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "backend" {
  name                  = "tfstate"
  resource_group_name   = "${azurerm_resource_group.backend.name}"
  storage_account_name  = "${azurerm_storage_account.backend.name}"
  container_access_type = "private"
}
