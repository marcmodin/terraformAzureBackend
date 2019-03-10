variable "network_resource_group_name" {}

variable "default_resource_group_location" {}
variable "network_vnet_name" {}

variable "network_vnet_address_space" {
  type = "list"
}

variable "network_subnet_cidrs" {
  type = "map"
}
