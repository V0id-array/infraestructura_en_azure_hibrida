resource "random_string" "uid" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}-${var.location}"
  location = var.location
  tags     = merge(var.tags, { Entorno = var.environment })
}

module "networking" {
  source = "./modules/networking"

  resource_group_name            = azurerm_resource_group.main.name
  location                       = azurerm_resource_group.main.location
  project_name                   = var.project_name
  environment                    = var.environment
  tags                           = var.tags
  hub_vnet_address_space         = var.hub_vnet_address_space
  woocommerce_vnet_address_space = var.woocommerce_vnet_address_space
  corporate_vnet_address_space   = var.corporate_vnet_address_space
  on_premises_sites              = var.on_premises_sites
}

module "security" {
  source = "./modules/security"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_name        = var.project_name
  environment         = var.environment
  tags                = var.tags
  uid                 = random_string.uid.result
}

module "corporate_storage" {
  source = "./modules/corporate-storage"

  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  project_name            = var.project_name
  environment             = var.environment
  tags                    = var.tags
  uid                     = random_string.uid.result
  purview_managed_rg_name = var.purview_managed_rg_name

  corporate_subnet_storage_id = module.networking.corporate_subnet_storage_id
  corporate_vnet_id           = module.networking.corporate_vnet_id

  log_analytics_workspace_id = module.security.log_analytics_workspace_id
}

module "arc" {
  source = "./modules/arc"
  count  = var.arc_enabled ? 1 : 0

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_name        = var.project_name
  environment         = var.environment
  tags                = var.tags

  log_analytics_workspace_id  = module.security.log_analytics_workspace_id
  log_analytics_workspace_key = module.security.log_analytics_workspace_key
}

module "woocommerce" {
  source = "./modules/woocommerce"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_name        = var.project_name
  environment         = var.environment
  tags                = var.tags
  uid                 = random_string.uid.result

  aks_node_count   = var.aks_node_count
  aks_node_vm_size = var.aks_node_vm_size

  mysql_sku_name       = var.mysql_sku_name
  mysql_admin_username = var.mysql_admin_username
  mysql_admin_password = var.mysql_admin_password

  aks_subnet_id   = module.networking.woocommerce_subnet_aks_id
  db_subnet_id    = module.networking.woocommerce_subnet_db_id
  cache_subnet_id = module.networking.woocommerce_subnet_cache_id
  woo_vnet_id     = module.networking.woocommerce_vnet_id

  log_analytics_workspace_id = module.security.log_analytics_workspace_id
  key_vault_id               = module.security.key_vault_id
}

module "active_directory" {
  source = "./modules/active-directory"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_name        = var.project_name
  environment         = var.environment
  tags                = var.tags
  uid                 = random_string.uid.result

  subnet_id      = module.networking.hub_management_subnet_id
  dc_count       = var.ad_dc_count
  vm_size        = var.ad_vm_size
  admin_username = var.ad_admin_username
  admin_password = var.ad_admin_password

  ad_domain_name  = var.ad_domain_name
  ad_netbios_name = var.ad_netbios_name

  log_analytics_workspace_id = module.security.log_analytics_workspace_id
  key_vault_id               = module.security.key_vault_id
}

module "backup" {
  source = "./modules/backup"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_name        = var.project_name
  environment         = var.environment
  tags                = var.tags

  vm_ids   = module.active_directory.dc_ids
  vm_names = module.active_directory.dc_names

  storage_account_id   = module.corporate_storage.storage_account_id
  storage_account_name = module.corporate_storage.storage_account_name
  file_share_name      = module.corporate_storage.file_share_name

  arc_enabled = var.arc_enabled
}


