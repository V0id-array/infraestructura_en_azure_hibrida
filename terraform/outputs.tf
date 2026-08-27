output "resource_group_name" {
  description = "Nombre del RG principal"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID del Resource Group"
  value       = azurerm_resource_group.main.id
}

output "hub_vnet_name" {
  description = "Nombre de la VNet Hub"
  value       = module.networking.hub_vnet_name
}

output "hub_vnet_id" {
  description = "Resource ID de la VNet Hub"
  value       = module.networking.hub_vnet_id
}

output "vpn_gateway_public_ip" {
  description = "IP publica para la VPN S2S"
  value       = module.networking.vpn_gateway_public_ip
}

output "log_analytics_workspace_id" {
  description = "ID del workspace de logs"
  value       = module.security.log_analytics_workspace_id
}

output "sentinel_workspace_name" {
  description = "Workspace con Sentinel activo"
  value       = module.security.sentinel_workspace_name
}

output "key_vault_name" {
  description = "Nombre del Key Vault"
  value       = module.security.key_vault_name
}

output "storage_account_name" {
  description = "Storage account corporativo"
  value       = module.corporate_storage.storage_account_name
}

output "file_share_url" {
  description = "Endpoint UNC/URL del file share"
  value       = module.corporate_storage.file_share_url
}

output "purview_account_name" {
  description = "Cuenta de Purview"
  value       = module.corporate_storage.purview_account_name
}

output "aks_cluster_name" {
  description = "Nombre del cluster AKS"
  value       = module.woocommerce.aks_cluster_name
}

output "aks_kube_config_command" {
  description = "Comando para bajar el kubeconfig"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.woocommerce.aks_cluster_name}"
}

output "acr_login_server" {
  description = "Login server del registry"
  value       = module.woocommerce.acr_login_server
}

output "mysql_server_fqdn" {
  description = "FQDN interno de MySQL"
  value       = module.woocommerce.mysql_server_fqdn
  sensitive   = true
}

output "arc_onboarding_script_info" {
  description = "Datos para onboarding de Arc"
  value       = var.arc_enabled ? module.arc[0].onboarding_info : "Arc no habilitado"
}

output "ad_domain_name" {
  description = "FQDN de Active Directory"
  value       = module.active_directory.ad_domain_name
}

output "ad_dc_ips" {
  description = "IPs estaticas de los DCs"
  value       = module.active_directory.dc_private_ips
}

output "ad_dc_names" {
  description = "Hostnames de los DCs"
  value       = module.active_directory.dc_names
}

output "ad_join_fileshare_command" {
  description = "Comando para unir el storage a AD"
  value       = ".\\scripts\\04-join-storage-to-ad.ps1 -StorageAccountName ${module.corporate_storage.storage_account_name} -ResourceGroupName ${azurerm_resource_group.main.name}"
}

output "recovery_services_vault_name" {
  description = "Nombre del vault de backup"
  value       = module.backup.recovery_services_vault_name
}

output "vm_backup_policy_id" {
  description = "ID de la policy de backup de VMs"
  value       = module.backup.vm_backup_policy_id
}

output "storage_sync_service_name" {
  description = "Servicio de Azure File Sync"
  value       = module.corporate_storage.storage_sync_service_name
}

output "storage_sync_group_name" {
  description = "Sync group de archivos"
  value       = module.corporate_storage.storage_sync_group_name
}


