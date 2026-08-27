output "recovery_services_vault_id" {
  description = "ID del Recovery Services Vault"
  value       = azurerm_recovery_services_vault.vault.id
}

output "recovery_services_vault_name" {
  description = "Nombre del vault"
  value       = azurerm_recovery_services_vault.vault.name
}

output "vm_backup_policy_id" {
  description = "ID de la policy de backup de VMs"
  value       = azurerm_backup_policy_vm.cloud_vms.id
}

output "file_share_backup_policy_id" {
  description = "ID de la policy de backup de fileshare"
  value       = azurerm_backup_policy_file_share.corporate.id
}

