output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  value = azurerm_storage_account.corp.name
}

output "file_share_name" {
  value = azurerm_storage_share.corporate.name
}

output "purview_account_name" {
  value = azurerm_purview_account.purview.name
}

output "purview_studio_endpoint" {
  value = azurerm_purview_account.purview.catalog_endpoint
}
