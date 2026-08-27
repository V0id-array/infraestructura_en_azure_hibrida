output "aks_cluster_name" {
  description = "Nombre del cluster AKS"
  value       = azurerm_kubernetes_cluster.woo.name
}

output "aks_cluster_id" {
  description = "Resource ID de AKS"
  value       = azurerm_kubernetes_cluster.woo.id
}

output "acr_login_server" {
  description = "Login server de ACR"
  value       = azurerm_container_registry.woo.login_server
}

output "acr_name" {
  description = "Nombre del registry"
  value       = azurerm_container_registry.woo.name
}

output "mysql_server_fqdn" {
  description = "FQDN de MySQL Flexible"
  value       = azurerm_mysql_flexible_server.woo.fqdn
  sensitive   = true
}

output "mysql_database_name" {
  description = "Nombre de la base de datos"
  value       = azurerm_mysql_flexible_database.wordpress.name
}

output "redis_hostname" {
  description = "Hostname de Redis"
  value       = azurerm_redis_cache.woo.hostname
}

output "redis_ssl_port" {
  description = "Puerto SSL de Redis"
  value       = azurerm_redis_cache.woo.ssl_port
}

output "redis_primary_access_key" {
  description = "Clave de acceso de Redis"
  value       = azurerm_redis_cache.woo.primary_access_key
  sensitive   = true
}

output "frontdoor_endpoint_hostname" {
  description = "Hostname de Front Door"
  value       = azurerm_cdn_frontdoor_endpoint.woo.host_name
}

output "frontdoor_profile_id" {
  description = "ID del perfil Front Door"
  value       = azurerm_cdn_frontdoor_profile.woo.id
}

