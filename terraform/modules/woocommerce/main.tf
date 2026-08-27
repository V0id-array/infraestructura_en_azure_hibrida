locals {
  prefix = "${var.project_name}-${var.environment}"
}

resource "azurerm_container_registry" "woo" {
  name                = "acrwoo${var.uid}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = false
  tags                = merge(var.tags, { Componente = "WooCommerce-ACR" })
}

resource "azurerm_kubernetes_cluster" "woo" {
  name                = "aks-woo-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = "aks-woo-${local.prefix}"
  kubernetes_version  = var.aks_kubernetes_version
  tags                = merge(var.tags, { Componente = "WooCommerce-AKS" })

  default_node_pool {
    name                = "system"
    vm_size             = var.aks_node_vm_size
    vnet_subnet_id      = var.aks_subnet_id
    os_disk_size_gb     = 50
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 5
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    service_cidr      = "10.100.0.0/16"
    dns_service_ip    = "10.100.0.10"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  oidc_issuer_enabled = true
}

resource "azurerm_role_assignment" "aks_acr" {
  scope                = azurerm_container_registry.woo.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.woo.kubelet_identity[0].object_id
}

# MySQL Flexible Server + Private DNS
resource "azurerm_private_dns_zone" "mysql" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "link-mysql-woo"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = var.woo_vnet_id
  registration_enabled  = false
}

resource "azurerm_mysql_flexible_server" "woo" {
  name                   = "mysql-woo-${local.prefix}"
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password
  sku_name               = var.mysql_sku_name
  zone                   = "1"
  version                = "8.0.21"
  tags                   = merge(var.tags, { Componente = "WooCommerce-MySQL" })

  delegated_subnet_id = var.db_subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.mysql.id

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  storage {
    size_gb           = 20
    auto_grow_enabled = true
    iops              = 360
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql]
}

resource "azurerm_mysql_flexible_database" "wordpress" {
  name                = "wordpress_db"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.woo.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

resource "azurerm_redis_cache" "woo" {
  name                = "redis-woo-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
  minimum_tls_version = "1.2"
  tags                = merge(var.tags, { Componente = "WooCommerce-Redis" })

  redis_configuration {
    maxmemory_policy = "allkeys-lru"
  }
}

# Front Door + WAF
resource "azurerm_cdn_frontdoor_profile" "woo" {
  name                = "afd-woo-${local.prefix}"
  resource_group_name = var.resource_group_name
  sku_name            = "Premium_AzureFrontDoor"
  tags                = merge(var.tags, { Componente = "WooCommerce-FrontDoor" })
}

resource "azurerm_cdn_frontdoor_endpoint" "woo" {
  name                     = "ep-woo-${local.prefix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.woo.id
  tags                     = var.tags
}

resource "azurerm_cdn_frontdoor_firewall_policy" "woo" {
  name                              = "wafwoo${var.uid}"
  resource_group_name               = var.resource_group_name
  sku_name                          = azurerm_cdn_frontdoor_profile.woo.sku_name
  enabled                           = true
  mode                              = "Prevention"
  custom_block_response_status_code = 403

  managed_rule {
    type    = "Microsoft_DefaultRuleSet"
    version = "1.1"
    action  = "Block"
  }

  tags = var.tags
}

resource "azurerm_cdn_frontdoor_security_policy" "woo" {
  name                     = "secpolicywoo"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.woo.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.woo.id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.woo.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "diag-aks-woo-to-law"
  target_resource_id         = azurerm_kubernetes_cluster.woo.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

