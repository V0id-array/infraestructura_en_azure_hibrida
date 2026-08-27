output "dc_private_ips" {
  description = "IPs estaticas de los DCs"
  value       = [for nic in azurerm_network_interface.dc : nic.private_ip_address]
}

output "dc_names" {
  description = "Hostnames de los DCs"
  value       = [for vm in azurerm_windows_virtual_machine.dc : vm.name]
}

output "dc_ids" {
  description = "Resource IDs de las VMs"
  value       = [for vm in azurerm_windows_virtual_machine.dc : vm.id]
}

output "lb_private_ip" {
  description = "IP del balanceador de DNS/LDAP"
  value       = azurerm_lb.dc.private_ip_address
}

output "ad_domain_name" {
  description = "FQDN del dominio"
  value       = var.ad_domain_name
}

output "ad_netbios_name" {
  description = "NetBIOS del dominio"
  value       = var.ad_netbios_name
}

output "dns_servers" {
  description = "Servidores DNS a configurar en VNets"
  value       = [azurerm_lb.dc.private_ip_address]
}

