output "vnet_resource_group" {
  value = "${azurerm_resource_group.net.name}"
}

output "vnet_name" {
  value = "${azurerm_virtual_network.net.name}"
}

output "vnet_id" {
  value = "${azurerm_virtual_network.net.id}"
}

# return vnet_cidr as string
output "vnet_address_space" {
  value = "${element(azurerm_virtual_network.net.address_space, 0)}"
}

output "subnets_id_map" {
  value = "${zipmap(azurerm_subnet.net.*.name, azurerm_subnet.net.*.id)}"
}
