resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  location            = var.location
  resource_group_name = "rg-corporate-purview-${var.environment}"
  uid                 = random_string.suffix.result
  tags = {
    Proyecto    = "GovernanceAndStorage"
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.tags
}

resource "azurerm_storage_account" "corp" {
  name                     = "stcorpfiles${local.uid}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
  tags                     = local.tags

  allow_nested_items_to_be_public = false

  share_properties {
    retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_share" "corporate" {
  name                 = "share-corporate"
  storage_account_name = azurerm_storage_account.corp.name
  quota                = 100
  access_tier          = "TransactionOptimized"
  enabled_protocol     = "SMB"
}

resource "azurerm_storage_share_directory" "departments" {
  for_each = toset(["Direccion", "RRHH", "Finanzas", "IT", "Legal", "Operaciones"])

  name             = each.key
  storage_share_id = azurerm_storage_share.corporate.id
}

resource "azurerm_purview_account" "purview" {
  name                        = "purview-corp-${local.uid}"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = var.purview_location
  managed_resource_group_name = "rg-purview-managed-${local.uid}"
  public_network_enabled      = true
  tags                        = local.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "purview_storage_blob_reader" {
  scope                = azurerm_storage_account.corp.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_purview_account.purview.identity[0].principal_id
}

resource "azurerm_role_assignment" "purview_storage_reader" {
  scope                = azurerm_storage_account.corp.id
  role_definition_name = "Reader"
  principal_id         = azurerm_purview_account.purview.identity[0].principal_id
}

