# Configure the Azure Provider
# Use az login to autheticate with azure
provider "azurerm" {}

# Initilize Terraform to use remote backend \
# grabbing its config from backend.tfvars \
# terraform init -backend-config="../backend.tfvars"
terraform {
  backend "azurerm" {
    key = "dev/network/vnet.tfstate"
  }
}

resource "azurerm_resource_group" "net" {
  name     = "${var.network_resource_group_name}"
  location = "${var.default_resource_group_location}"
}

# Create Virtual Network
resource "azurerm_virtual_network" "net" {
  name                = "${var.network_vnet_name}"
  address_space       = ["${var.network_vnet_address_space}"]
  location            = "${var.default_resource_group_location}"
  resource_group_name = "${azurerm_resource_group.net.name}"
}

resource "azurerm_subnet" "net" {
  count = "${length(keys(var.network_subnet_cidrs))}"

  # some map magic on var.network_subnet_cidrs 
  name           = "${element(keys(var.network_subnet_cidrs),count.index)}"
  address_prefix = "${lookup(var.network_subnet_cidrs, element(keys(var.network_subnet_cidrs),count.index))}"

  resource_group_name  = "${var.network_resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.net.name}"
}

resource "azurerm_network_security_group" "net" {
  name                = "default-security-group"
  location            = "${var.default_resource_group_location}"
  resource_group_name = "${azurerm_resource_group.net.name}"
}

resource "azurerm_subnet_network_security_group_association" "net" {
  count                     = "${length(keys(var.network_subnet_cidrs))}"
  subnet_id                 = "${element(azurerm_subnet.net.*.id, count.index)}"
  network_security_group_id = "${azurerm_network_security_group.net.id}"
}
