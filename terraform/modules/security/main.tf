data "azurerm_client_config" "current" {}

locals {
  prefix = "${var.project_name}-${var.environment}"
}

resource "azurerm_log_analytics_workspace" "central" {
  name                = "law-central-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days
  tags                = merge(var.tags, { Componente = "Monitorización" })
  daily_quota_gb      = -1
}

resource "azurerm_sentinel_log_analytics_workspace_onboarding" "sentinel" {
  count = var.sentinel_enabled ? 1 : 0

  workspace_id = azurerm_log_analytics_workspace.central.id
}

# Regla para detectar intentos fallidos continuados
resource "azurerm_sentinel_alert_rule_scheduled" "brute_force" {
  count = var.sentinel_enabled ? 1 : 0

  name                       = "rule-brute-force-detection"
  display_name               = "Detección de intentos de fuerza bruta"
  description                = "Detecta intentos fallidos repetidos desde la misma IP."
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id
  severity                   = "High"
  enabled                    = true

  query = <<-QUERY
    SigninLogs
    | where ResultType != "0"
    | summarize FailedAttempts = count() by IPAddress, bin(TimeGenerated, 5m)
    | where FailedAttempts > 10
  QUERY

  query_frequency = "PT5M"
  query_period    = "PT30M"

  trigger_operator  = "GreaterThan"
  trigger_threshold = 0

  tactics = ["InitialAccess", "CredentialAccess"]

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.sentinel]
}

resource "azurerm_key_vault" "main" {
  name                       = "kv-${var.project_name}-${var.uid}"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 90
  purge_protection_enabled   = true
  tags                       = merge(var.tags, { Componente = "Seguridad" })

  enable_rbac_authorization = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "diag-keyvault-to-law"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_user_assigned_identity" "app_identity" {
  name                = "id-app-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "app_kv_reader" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app_identity.principal_id
}

resource "azurerm_application_insights" "woocommerce" {
  name                = "appi-woocommerce-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.central.id
  application_type    = "web"
  tags                = merge(var.tags, { Componente = "Monitorización-WooCommerce" })
}

resource "azurerm_monitor_action_group" "ops_team" {
  name                = "ag-ops-${local.prefix}"
  resource_group_name = var.resource_group_name
  short_name          = "opsalerts"

  email_receiver {
    name                    = "AdminEmail"
    email_address           = var.alert_email_receiver
    use_common_alert_schema = true
  }

  tags = var.tags
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "high_cpu" {
  name                = "alert-high-cpu-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  scopes               = [azurerm_log_analytics_workspace.central.id]
  severity             = 2

  criteria {
    query = <<-QUERY
      Perf
      | where ObjectName == "Processor" and CounterName == "% Processor Time"
      | summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
      | where AggregatedValue > 85
    QUERY

    metric_measure_column   = "AggregatedValue"
    time_aggregation_method = "Average"
    threshold               = 85
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.ops_team.id]
  }

  tags = var.tags
}


