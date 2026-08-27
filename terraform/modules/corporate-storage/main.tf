locals {
  prefix = "${var.project_name}-${var.environment}"
}

resource "azurerm_storage_account" "corporate" {
  name                     = "stcorpfiles${var.uid}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
  tags                     = merge(var.tags, { Componente = "AlmacenamientoCorporativo" })

  allow_nested_items_to_be_public = false
  infrastructure_encryption_enabled = true

  network_rules {
    default_action             = "Allow"
    bypass                     = ["AzureServices", "Logging", "Metrics"]
    virtual_network_subnet_ids = [var.corporate_subnet_storage_id]
  }

  blob_properties {
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }

  share_properties {
    retention_policy {
      days = 30
    }
    smb {
      versions                        = ["SMB3.0", "SMB3.1.1"]
      authentication_types            = ["Kerberos", "NTLMv2"]
      channel_encryption_type         = ["AES-128-CCM", "AES-128-GCM", "AES-256-GCM"]
      kerberos_ticket_encryption_type = ["AES-256"]
    }
  }
}

resource "azurerm_storage_share" "corporate" {
  name                 = "share-corporate"
  storage_account_name = azurerm_storage_account.corporate.name
  quota                = var.file_share_quota_gb
  access_tier          = "TransactionOptimized"
  enabled_protocol     = "SMB"
}

# Estructura inicial de carpetas
resource "azurerm_storage_share_directory" "departments" {
  for_each = toset(["Direccion", "RRHH", "Finanzas", "IT", "Legal", "Operaciones"])

  name             = each.key
  storage_share_id = azurerm_storage_share.corporate.id
}

# Private Endpoint + Private DNS
resource "azurerm_private_endpoint" "storage" {
  name                = "pe-storage-corp-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.corporate_subnet_storage_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-storage-corp"
    private_connection_resource_id = azurerm_storage_account.corporate.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }
}

resource "azurerm_private_dns_zone" "storage_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_file" {
  name                  = "link-storage-file-corp"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file.name
  virtual_network_id    = var.corporate_vnet_id
  registration_enabled  = false
}

resource "azurerm_private_dns_a_record" "storage_file" {
  name                = azurerm_storage_account.corporate.name
  zone_name           = azurerm_private_dns_zone.storage_file.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage.private_service_connection[0].private_ip_address]
}

resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "diag-storage-corp-to-law"
  target_resource_id         = "${azurerm_storage_account.corporate.id}/fileServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
    enabled  = true
  }
}

resource "azurerm_purview_account" "main" {
  name                = "purview-corp-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = "eastus2"
  tags                = merge(var.tags, { Componente = "GobiernoDeDatos" })

  managed_resource_group_name = var.purview_managed_rg_name

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "purview_storage_reader" {
  scope                = azurerm_storage_account.corporate.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_purview_account.main.identity[0].principal_id
}

# Permisos para el SP de Azure File Sync
resource "azurerm_role_assignment" "storage_sync_contributor" {
  scope                = azurerm_storage_account.corporate.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = "aa304b01-9e60-42e5-880e-00878dc748cd"
}

resource "azurerm_role_assignment" "storage_sync_data_reader" {
  scope                = azurerm_storage_account.corporate.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = "aa304b01-9e60-42e5-880e-00878dc748cd"
}

resource "azurerm_storage_sync" "corporate" {
  name                = "afs-corp-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = merge(var.tags, { Componente = "FileSync" })
}

resource "azurerm_storage_sync_group" "corporate" {
  name            = "sg-corp-${local.prefix}"
  storage_sync_id = azurerm_storage_sync.corporate.id
}

resource "azurerm_storage_sync_cloud_endpoint" "corporate" {
  name                  = "ce-corp-${local.prefix}"
  storage_sync_group_id = azurerm_storage_sync_group.corporate.id
  file_share_name       = azurerm_storage_share.corporate.name
  storage_account_id    = azurerm_storage_account.corporate.id

  depends_on = [
    azurerm_role_assignment.storage_sync_contributor,
    azurerm_role_assignment.storage_sync_data_reader
  ]
}

