# Configure the Azure Provider
# Use az login to autheticate with azure
provider "azurerm" {}

# Initilize Terraform to use remote backend \
# grabbing its config from backend.tfvars \
# terraform init -backend-config="../backend.tfvars"

terraform {
  backend "azurerm" {
    key = "dev/loadbalancers/ilb.tfstate"
  }
}

resource "azurerm_resource_group" "lb" {
  name     = "${var.lb_resource_group_name}"
  location = "${var.default_resource_group_location}"
}

resource "azurerm_lb" "ilb" {
  name                = "${var.internal_lb_name}"
  location            = "${var.default_resource_group_location}"
  resource_group_name = "${azurerm_resource_group.lb.name}"
  sku                 = "Basic"

  frontend_ip_configuration {
    name                          = "${var.internal_lb_name}-config"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${lookup(data.terraform_remote_state.remote.subnets_id_map, "consul")}"
  }
}

# # Public facing IP if this is public LB
# resource "azurerm_public_ip" "flb" {
#   name                = "PublicIPForFLB"
#   location            = "${var.default_resource_group_location}"
#   resource_group_name = "${azurerm_resource_group.lb.name}"
#   allocation_method   = "Static"
# }


# resource "azurerm_lb" "flb" {
#   name                = "${var.frontend_lb_name}"
#   location            = "${var.default_resource_group_location}"
#   resource_group_name = "${azurerm_resource_group.lb.name}"
#   sku                 = "Basic"


#   frontend_ip_configuration {
#     name                 = "${var.frontend_lb_name}-config"
#     public_ip_address_id = "${azurerm_public_ip.flb.id}"
#   }
# }

