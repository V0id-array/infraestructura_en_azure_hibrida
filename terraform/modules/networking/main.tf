locals {
  prefix = "${var.project_name}-${var.environment}"

  # Subredes del hub
  hub_subnets = {
    "AzureFirewallSubnet" = {
      address_prefixes = ["10.0.1.0/26"]
      delegation       = null
    }
    "GatewaySubnet" = {
      address_prefixes = ["10.0.2.0/27"]
      delegation       = null
    }
    "AzureBastionSubnet" = {
      address_prefixes = ["10.0.3.0/26"]
      delegation       = null
    }
    "snet-management" = {
      address_prefixes = ["10.0.4.0/24"]
      delegation       = null
    }
  }
}


# ─── VNet Hub ─────────────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${var.location}"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.hub_vnet_address_space
  tags                = merge(var.tags, { Componente = "Networking-Hub" })
}

resource "azurerm_subnet" "hub" {
  for_each = local.hub_subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = each.value.address_prefixes
}

# ─── VNet Spoke WooCommerce ──────────────────────────────────────────────────

resource "azurerm_virtual_network" "woocommerce" {
  name                = "vnet-woocommerce-${var.location}"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.woocommerce_vnet_address_space
  tags                = merge(var.tags, { Componente = "Networking-WooCommerce" })
}

resource "azurerm_subnet" "woo_aks" {
  name                 = "snet-aks-nodes"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.woocommerce.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "woo_db" {
  name                 = "snet-database"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.woocommerce.name
  address_prefixes     = ["10.1.10.0/24"]

  delegation {
    name = "mysql-delegation"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet" "woo_cache" {
  name                 = "snet-cache"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.woocommerce.name
  address_prefixes     = ["10.1.11.0/24"]
}

# ─── VNet Spoke Corporate ───────────────────────────────────────────────────

resource "azurerm_virtual_network" "corporate" {
  name                = "vnet-corporate-${var.location}"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.corporate_vnet_address_space
  tags                = merge(var.tags, { Componente = "Networking-Corporate" })
}

resource "azurerm_subnet" "corp_storage" {
  name                 = "snet-storage"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.corporate.name
  address_prefixes     = ["10.2.1.0/24"]

  service_endpoints = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "corp_purview" {
  name                 = "snet-purview"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.corporate.name
  address_prefixes     = ["10.2.2.0/24"]
}

resource "azurerm_subnet" "corp_keyvault" {
  name                 = "snet-keyvault"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.corporate.name
  address_prefixes     = ["10.2.3.0/24"]

  service_endpoints = ["Microsoft.KeyVault"]
}

# ─── VNet Peerings (Hub ↔ Spokes) ────────────────────────────────────────────

# Hub → WooCommerce
resource "azurerm_virtual_network_peering" "hub_to_woo" {
  name                         = "peer-hub-to-woocommerce"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.woocommerce.id
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  allow_virtual_network_access = true
}

# WooCommerce → Hub
resource "azurerm_virtual_network_peering" "woo_to_hub" {
  name                         = "peer-woocommerce-to-hub"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.woocommerce.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_forwarded_traffic      = true
  use_remote_gateways          = length(var.on_premises_sites) > 0 ? true : false
  allow_virtual_network_access = true

  depends_on = [azurerm_virtual_network_gateway.vpn]
}

# Hub → Corporate
resource "azurerm_virtual_network_peering" "hub_to_corp" {
  name                         = "peer-hub-to-corporate"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.corporate.id
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  allow_virtual_network_access = true
}

# Corporate → Hub
resource "azurerm_virtual_network_peering" "corp_to_hub" {
  name                         = "peer-corporate-to-hub"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.corporate.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_forwarded_traffic      = true
  use_remote_gateways          = length(var.on_premises_sites) > 0 ? true : false
  allow_virtual_network_access = true

  depends_on = [azurerm_virtual_network_gateway.vpn]
}

# ─── NSGs ─────────────────────────────────────────────────────────────────────

resource "azurerm_network_security_group" "management" {
  name                = "nsg-management-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowRDP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "management" {
  subnet_id                 = azurerm_subnet.hub["snet-management"].id
  network_security_group_id = azurerm_network_security_group.management.id
}

resource "azurerm_network_security_group" "aks" {
  name                = "nsg-aks-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.woo_aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

resource "azurerm_network_security_group" "database" {
  name                = "nsg-database-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rule {
    name                       = "AllowMySQLFromAKS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "10.1.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = azurerm_subnet.woo_db.id
  network_security_group_id = azurerm_network_security_group.database.id
}

resource "azurerm_network_security_group" "storage" {
  name                = "nsg-storage-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rule {
    name                       = "AllowSMBFromVPN"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "445"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "storage" {
  subnet_id                 = azurerm_subnet.corp_storage.id
  network_security_group_id = azurerm_network_security_group.storage.id
}

# ─── Azure Firewall ──────────────────────────────────────────────────────────

resource "azurerm_public_ip" "firewall" {
  name                = "pip-firewall-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall" "hub" {
  name                = "fw-hub-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.hub["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

# Regla de red: permitir tráfico saliente a Internet desde los spokes
resource "azurerm_firewall_network_rule_collection" "allow_outbound" {
  name                = "fwrc-allow-outbound"
  azure_firewall_name = azurerm_firewall.hub.name
  resource_group_name = var.resource_group_name
  priority            = 100
  action              = "Allow"

  rule {
    name                  = "AllowDNS"
    source_addresses      = ["10.0.0.0/8"]
    destination_ports     = ["53"]
    destination_addresses = ["*"]
    protocols             = ["TCP", "UDP"]
  }

  rule {
    name                  = "AllowHTTPS"
    source_addresses      = ["10.0.0.0/8"]
    destination_ports     = ["443"]
    destination_addresses = ["*"]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "AllowHTTP"
    source_addresses      = ["10.0.0.0/8"]
    destination_ports     = ["80"]
    destination_addresses = ["*"]
    protocols             = ["TCP"]
  }
}

# ─── Azure Bastion ───────────────────────────────────────────────────────────

resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "hub" {
  name                = "bastion-hub-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  tags                = var.tags

  tunneling_enabled      = true
  file_copy_enabled      = true
  copy_paste_enabled     = true
  shareable_link_enabled = true

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = azurerm_subnet.hub["AzureBastionSubnet"].id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

# ─── VPN Gateway (para conexiones Site-to-Site con sedes) ─────────────────────

resource "azurerm_public_ip" "vpn_gateway" {
  name                = "pip-vpngw-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "vpn" {
  name                = "vpngw-hub-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1AZ"
  active_active       = false
  enable_bgp          = false
  tags                = var.tags

  ip_configuration {
    name                          = "vpngw-ipconfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.hub["GatewaySubnet"].id
  }
}

# ─── Local Network Gateways + Connections (para cada sede on-premises) ────────

resource "azurerm_local_network_gateway" "sites" {
  for_each = var.on_premises_sites

  name                = "lgw-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location
  gateway_address     = each.value.gateway_ip
  address_space       = each.value.address_space
  tags                = merge(var.tags, { Sede = each.value.description })
}

resource "azurerm_virtual_network_gateway_connection" "site_connections" {
  for_each = var.on_premises_sites

  name                       = "vpnconn-${each.key}"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn.id
  local_network_gateway_id   = azurerm_local_network_gateway.sites[each.key].id
  shared_key                 = each.value.shared_key
  tags                       = merge(var.tags, { Sede = each.value.description })

  ipsec_policy {
    dh_group         = "DHGroup14"
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "PFS14"
    sa_lifetime      = 28800
    sa_datasize      = 102400000
  }
}
