# Variables reflect backend.tfvars variables
# usage:
# terraform apply -var-file="../../backend.tfvars" -var-file="../../terraform.tfvars"
variable "resource_group_name" {}

variable "storage_account_name" {}

variable "container_name" {}

variable "access_key" {}

# This data resource pulls vnet outputs
# available outputs: [vnet_name, vnet_id, vnet_address_space, subnets_id_map]
data "terraform_remote_state" "remote" {
  backend = "azurerm"

  config = {
    resource_group_name  = "${var.resource_group_name}"
    storage_account_name = "${var.storage_account_name}"
    container_name       = "${var.container_name}"
    access_key           = "${var.access_key}"

    key = "dev/network/vnet.tfstate"
  }
}
