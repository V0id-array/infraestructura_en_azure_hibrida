locals {
  prefix = "${var.project_name}-${var.environment}"
}

resource "azurerm_recovery_services_vault" "vault" {
  name                = "rsv-central-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  storage_mode_type   = "GeoRedundant"
  immutability        = "Disabled"

  soft_delete_enabled = true

  tags = merge(var.tags, { Componente = "Backup-Vault" })
}

# Politica diaria para VMs de AD
resource "azurerm_backup_policy_vm" "cloud_vms" {
  name                = "policy-backup-cloud-vms-${local.prefix}"
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name

  timezone = "W. Europe Standard Time"

  backup {
    frequency = "Daily"
    time      = "02:00"
  }

  retention_daily {
    count = 30
  }

  retention_weekly {
    count    = 4
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = 12
    weekdays = ["Sunday"]
    weeks    = ["Last"]
  }
}

resource "azurerm_backup_protected_vm" "dc" {
  count = length(var.vm_ids)

  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  source_vm_id        = var.vm_ids[count.index]
  backup_policy_id    = azurerm_backup_policy_vm.cloud_vms.id
}

# Backup para el file share
resource "azurerm_backup_container_storage_account" "storage" {
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  storage_account_id  = var.storage_account_id
}

resource "azurerm_backup_policy_file_share" "corporate" {
  name                = "policy-backup-fileshare-${local.prefix}"
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name

  timezone = "W. Europe Standard Time"

  backup {
    frequency = "Daily"
    time      = "03:00"
  }

  retention_daily {
    count = 30
  }

  retention_weekly {
    count    = 4
    weekdays = ["Sunday"]
  }
}

resource "azurerm_backup_protected_file_share" "corporate" {
  resource_group_name       = var.resource_group_name
  recovery_vault_name       = azurerm_recovery_services_vault.vault.name
  backup_policy_id          = azurerm_backup_policy_file_share.corporate.id
  source_storage_account_id = var.storage_account_id
  source_file_share_name    = var.file_share_name

  depends_on = [azurerm_backup_container_storage_account.storage]
}

data "azurerm_subscription" "current" {}

