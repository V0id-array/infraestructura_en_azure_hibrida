output "data_collection_rule_id" {
  description = "ID de la DCR para Arc"
  value       = azurerm_monitor_data_collection_rule.windows_servers.id
}

output "onboarding_info" {
  description = "Datos para onboarding de Arc"
  value       = <<-EOT
    Script: scripts/arc-onboard-windows.ps1
    RG: ${var.resource_group_name}
    Region: ${var.location}
    DCR: ${azurerm_monitor_data_collection_rule.windows_servers.name}
  EOT
}

