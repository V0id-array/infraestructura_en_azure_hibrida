output "hub_vnet_id" {
  description = "Resource ID de la VNet Hub"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Nombre de la VNet Hub"
  value       = azurerm_virtual_network.hub.name
}

output "hub_management_subnet_id" {
  description = "Subnet ID para DCs/gestion"
  value       = azurerm_subnet.hub["snet-management"].id
}

output "firewall_private_ip" {
  description = "IP privada de Azure Firewall"
  value       = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

output "vpn_gateway_public_ip" {
  description = "IP publica VPN Gateway"
  value       = azurerm_public_ip.vpn_gateway.ip_address
}

output "woocommerce_vnet_id" {
  description = "Resource ID de la VNet WooCommerce"
  value       = azurerm_virtual_network.woocommerce.id
}

output "woocommerce_subnet_aks_id" {
  description = "Subnet ID para los nodos AKS"
  value       = azurerm_subnet.woo_aks.id
}

output "woocommerce_subnet_db_id" {
  description = "Subnet delegada de MySQL"
  value       = azurerm_subnet.woo_db.id
}

output "woocommerce_subnet_cache_id" {
  description = "Subnet de Redis"
  value       = azurerm_subnet.woo_cache.id
}

output "corporate_vnet_id" {
  description = "Resource ID de la VNet Corporate"
  value       = azurerm_virtual_network.corporate.id
}

output "corporate_subnet_storage_id" {
  description = "Subnet para Private Endpoint de storage"
  value       = azurerm_subnet.corp_storage.id
}

output "corporate_subnet_purview_id" {
  description = "Subnet de Purview"
  value       = azurerm_subnet.corp_purview.id
}

output "corporate_subnet_keyvault_id" {
  description = "Subnet de Key Vault"
  value       = azurerm_subnet.corp_keyvault.id
}

