output "storage_account_name" {
  description = "Nombre de la storage account"
  value       = azurerm_storage_account.corporate.name
}

output "storage_account_id" {
  description = "Resource ID de la storage account"
  value       = azurerm_storage_account.corporate.id
}

output "file_share_url" {
  description = "Resource manager ID del share"
  value       = azurerm_storage_share.corporate.resource_manager_id
}

output "file_share_name" {
  description = "Nombre del share"
  value       = azurerm_storage_share.corporate.name
}

output "purview_account_name" {
  description = "Nombre de la cuenta Purview"
  value       = azurerm_purview_account.main.name
}

output "purview_account_id" {
  description = "ID de la cuenta Purview"
  value       = azurerm_purview_account.main.id
}

output "purview_catalog_endpoint" {
  description = "Endpoint del catalogo Purview"
  value       = azurerm_purview_account.main.catalog_endpoint
}

output "purview_identity_principal_id" {
  description = "Principal ID asignado a Purview"
  value       = azurerm_purview_account.main.identity[0].principal_id
}

output "storage_private_endpoint_ip" {
  description = "IP privada del private endpoint"
  value       = azurerm_private_endpoint.storage.private_service_connection[0].private_ip_address
}

output "storage_sync_service_name" {
  description = "Nombre del storage sync service"
  value       = azurerm_storage_sync.corporate.name
}

output "storage_sync_group_name" {
  description = "Nombre del sync group"
  value       = azurerm_storage_sync_group.corporate.name
}

