output "backend_resource_group_name" {
  value = "${azurerm_resource_group.backend.name}"
}

output "backend_storage_account_name" {
  value = "${azurerm_storage_account.backend.name}"
}

output "backend_storage_container_name" {
  value = "${azurerm_storage_container.backend.name}"
}

output "backend_storage_account_accesskey" {
  value = "${azurerm_storage_account.backend.primary_access_key}"
}
