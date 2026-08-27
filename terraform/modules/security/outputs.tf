output "log_analytics_workspace_id" {
  description = "Resource ID de Log Analytics"
  value       = azurerm_log_analytics_workspace.central.id
}

output "log_analytics_workspace_key" {
  description = "Clave primaria del workspace"
  value       = azurerm_log_analytics_workspace.central.primary_shared_key
  sensitive   = true
}

output "sentinel_workspace_name" {
  description = "Nombre del workspace con Sentinel"
  value       = azurerm_log_analytics_workspace.central.name
}

output "key_vault_id" {
  description = "Resource ID de Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Nombre de Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}

output "app_identity_id" {
  description = "ID de la Managed Identity de la app"
  value       = azurerm_user_assigned_identity.app_identity.id
}

output "app_identity_principal_id" {
  description = "Principal ID de la identidad"
  value       = azurerm_user_assigned_identity.app_identity.principal_id
}

output "app_identity_client_id" {
  description = "Client ID"
  value       = azurerm_user_assigned_identity.app_identity.client_id
}

output "application_insights_connection_string" {
  description = "Connection string de App Insights"
  value       = azurerm_application_insights.woocommerce.connection_string
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key"
  value       = azurerm_application_insights.woocommerce.instrumentation_key
  sensitive   = true
}

