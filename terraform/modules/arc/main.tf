locals {
  prefix = "${var.project_name}-${var.environment}"
}

# DCR para Azure Monitor Agent en servidores Windows conectados via Arc
resource "azurerm_monitor_data_collection_rule" "windows_servers" {
  name                = "dcr-windows-servers-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = merge(var.tags, { Componente = "AzureArc-Monitorización" })

  destinations {
    log_analytics {
      workspace_resource_id = var.log_analytics_workspace_id
      name                  = "law-destination"
    }
  }

  data_flow {
    streams      = ["Microsoft-Event", "Microsoft-Perf"]
    destinations = ["law-destination"]
  }

  data_sources {
    windows_event_log {
      name    = "windows-events"
      streams = ["Microsoft-Event"]
      x_path_queries = [
        "Application!*[System[(Level=1 or Level=2 or Level=3)]]",
        "Security!*[System[(band(Keywords,13510798882111488))]]",
        "System!*[System[(Level=1 or Level=2 or Level=3)]]",
      ]
    }

    performance_counter {
      name                          = "windows-perf"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor Information(_Total)\\% Processor Time",
        "\\Memory\\Available MBytes",
        "\\Memory\\% Committed Bytes In Use",
        "\\LogicalDisk(_Total)\\% Free Space",
        "\\LogicalDisk(_Total)\\Avg. Disk sec/Read",
        "\\LogicalDisk(_Total)\\Avg. Disk sec/Write",
        "\\Network Interface(*)\\Bytes Total/sec",
      ]
    }
  }
}

data "azurerm_subscription" "current" {}

