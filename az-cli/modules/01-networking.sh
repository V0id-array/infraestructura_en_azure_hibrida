#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.env"

echo "[01-networking] Creando Hub VNet..."
az network vnet create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${HUB_VNET_NAME}" \
  --address-prefixes "${HUB_VNET_PREFIX}" \
  --location "${LOCATION}" \
  --tags ${TAGS} \
  --output none

az network vnet subnet create \
  --resource-group "${RESOURCE_GROUP}" \
  --vnet-name "${HUB_VNET_NAME}" \
  --name "AzureFirewallSubnet" \
  --address-prefixes "${HUB_SNET_FW_PREFIX}" \
  --output none

az network vnet subnet create \
  --resource-group "${RESOURCE_GROUP}" \
  --vnet-name "${HUB_VNET_NAME}" \
  --name "GatewaySubnet" \
  --address-prefixes "${HUB_SNET_GW_PREFIX}" \
  --output none

az network vnet subnet create \
  --resource-group "${RESOURCE_GROUP}" \
  --vnet-name "${HUB_VNET_NAME}" \
  --name "AzureBastionSubnet" \
  --address-prefixes "${HUB_SNET_BASTION_PREFIX}" \
  --output none

az network vnet subnet create \
  --resource-group "${RESOURCE_GROUP}" \
  --vnet-name "${HUB_VNET_NAME}" \
  --name "${HUB_SNET_MGMT_NAME}" \
  --address-prefixes "${HUB_SNET_MGMT_PREFIX}" \
  --output none

echo "[01-networking] Creando VNet WooCommerce..."
az network vnet create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${WOO_VNET_NAME}" \
  --address-prefixes "${WOO_VNET_PREFIX}" \
  --location "${LOCATION}" \
  --tags ${TAGS} \
  --output none

az network vnet subnet create \
  --resource-group "${RESOURCE_GROUP}" \
  --vnet-name "${WOO_VNET_NAME}" \
  --name "${WOO_SNET_AKS_NAME}" \
  --address-prefixes "${WOO_SNET_AKS_PREFIX}" \
  --output none

az network vnet subnet create \
  --resource-group "${RESOURCE_GROUP}" \
  --vnet-name "${WOO_VNET_NAME}" \
  --name "${WOO_SNET_DB_NAME}" \
  --address-prefixes "${WOO_SNET_DB_PREFIX}" \
  --delegations "Microsoft.DBforMySQL/flexibleServers" \
  --output none

az network vnet subnet create \
  --resource-group "${RESOURCE_GROUP}" \
  --vnet-name "${WOO_VNET_NAME}" \
  --name "${WOO_SNET_CACHE_NAME}" \
  --address-prefixes "${WOO_SNET_CACHE_PREFIX}" \
  --output none

echo "[01-networking] Creando VNet Corporate..."
az network vnet create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${CORP_VNET_NAME}" \
  --address-prefixes "${CORP_VNET_PREFIX}" \
  --location "${LOCATION}" \
  --tags ${TAGS} \
  --output none

az network vnet subnet create \
  --resource-group "${RESOURCE_GROUP}" \
  --vnet-name "${CORP_VNET_NAME}" \
  --name "${CORP_SNET_STORAGE_NAME}" \
  --address-prefixes "${CORP_SNET_STORAGE_PREFIX}" \
  --output none

az network vnet subnet create \
  --resource-group "${RESOURCE_GROUP}" \
  --vnet-name "${CORP_VNET_NAME}" \
  --name "${CORP_SNET_PURVIEW_NAME}" \
  --address-prefixes "${CORP_SNET_PURVIEW_PREFIX}" \
  --output none

az network vnet subnet create \
  --resource-group "${RESOURCE_GROUP}" \
  --vnet-name "${CORP_VNET_NAME}" \
  --name "${CORP_SNET_KV_NAME}" \
  --address-prefixes "${CORP_SNET_KV_PREFIX}" \
  --output none

echo "[01-networking] Configurando peerings..."
az network vnet peering create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "peering-hub-to-woocommerce" \
  --vnet-name "${HUB_VNET_NAME}" \
  --remote-vnet "${WOO_VNET_NAME}" \
  --allow-vnet-access \
  --allow-forwarded-traffic \
  --output none

az network vnet peering create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "peering-woocommerce-to-hub" \
  --vnet-name "${WOO_VNET_NAME}" \
  --remote-vnet "${HUB_VNET_NAME}" \
  --allow-vnet-access \
  --allow-forwarded-traffic \
  --output none

az network vnet peering create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "peering-hub-to-corporate" \
  --vnet-name "${HUB_VNET_NAME}" \
  --remote-vnet "${CORP_VNET_NAME}" \
  --allow-vnet-access \
  --allow-forwarded-traffic \
  --output none

az network vnet peering create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "peering-corporate-to-hub" \
  --vnet-name "${CORP_VNET_NAME}" \
  --remote-vnet "${HUB_VNET_NAME}" \
  --allow-vnet-access \
  --allow-forwarded-traffic \
  --output none

# Bastion
az network public-ip create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "pip-bastion-${LOCATION}" \
  --location "${LOCATION}" \
  --sku Standard \
  --allocation-method Static \
  --tags ${TAGS} \
  --output none

az network bastion create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "bastion-hub-${LOCATION}" \
  --vnet-name "${HUB_VNET_NAME}" \
  --public-ip-address "pip-bastion-${LOCATION}" \
  --location "${LOCATION}" \
  --tags ${TAGS} \
  --output none 2>/dev/null || echo "Aviso: fallo al crear Bastion (puede ser tema de cuota)."

