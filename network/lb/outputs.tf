output "ilb_private_ip" {
  value = "${azurerm_lb.ilb.private_ip_address}"
}

output "ilb_private_id" {
  value = "${azurerm_lb.ilb.id}"
}

output "ilb_resource_group" {
  value = "${azurerm_resource_group.lb.name}"
}
