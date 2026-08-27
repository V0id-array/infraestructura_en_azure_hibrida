#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.env"

SUBNET_MGMT_ID=$(az network vnet subnet show \
  --resource-group "${RESOURCE_GROUP}" \
  --vnet-name "${HUB_VNET_NAME}" \
  --name "${HUB_SNET_MGMT_NAME}" \
  --query id -o tsv)

echo "[04-active-directory] Creando Load Balancer interno..."
az network lb create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${AD_ILB_NAME}" \
  --location "${LOCATION}" \
  --sku Standard \
  --vnet-name "${HUB_VNET_NAME}" \
  --subnet "${HUB_SNET_MGMT_NAME}" \
  --private-ip-address "${AD_ILB_IP}" \
  --frontend-ip-name "ad-ilb-frontend" \
  --backend-pool-name "ad-backend-pool" \
  --tags ${TAGS} \
  --output none

az network lb probe create \
  --resource-group "${RESOURCE_GROUP}" \
  --lb-name "${AD_ILB_NAME}" \
  --name "ad-dns-probe" \
  --protocol tcp \
  --port 53 \
  --output none

az network lb rule create \
  --resource-group "${RESOURCE_GROUP}" \
  --lb-name "${AD_ILB_NAME}" \
  --name "ad-dns-rule" \
  --protocol Udp \
  --frontend-port 53 \
  --backend-port 53 \
  --frontend-ip-name "ad-ilb-frontend" \
  --backend-pool-name "ad-backend-pool" \
  --probe-name "ad-dns-probe" \
  --output none

echo "[04-active-directory] Desplegando DC1 (Zona 1)..."
az vm create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${AD_DC1_NAME}" \
  --location "${LOCATION}" \
  --zone 1 \
  --image "Win2022Datacenter" \
  --size "${AD_VM_SIZE}" \
  --admin-username "${AD_ADMIN_USER}" \
  --admin-password "${AD_ADMIN_PASS}" \
  --subnet "${SUBNET_MGMT_ID}" \
  --private-ip-address "10.0.4.4" \
  --public-ip-address "" \
  --os-disk-name "disk-${AD_DC1_NAME}-os" \
  --storage-sku StandardSSD_LRS \
  --tags ${TAGS} \
  --output none

# Disco dedicado para la base de datos de AD
az vm disk attach \
  --resource-group "${RESOURCE_GROUP}" \
  --vm-name "${AD_DC1_NAME}" \
  --name "disk-${AD_DC1_NAME}-ntds" \
  --new \
  --size-gb 32 \
  --sku Premium_LRS \
  --output none

echo "[04-active-directory] Desplegando DC2 (Zona 2)..."
az vm create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${AD_DC2_NAME}" \
  --location "${LOCATION}" \
  --zone 2 \
  --image "Win2022Datacenter" \
  --size "${AD_VM_SIZE}" \
  --admin-username "${AD_ADMIN_USER}" \
  --admin-password "${AD_ADMIN_PASS}" \
  --subnet "${SUBNET_MGMT_ID}" \
  --private-ip-address "10.0.4.5" \
  --public-ip-address "" \
  --os-disk-name "disk-${AD_DC2_NAME}-os" \
  --storage-sku StandardSSD_LRS \
  --tags ${TAGS} \
  --output none

az vm disk attach \
  --resource-group "${RESOURCE_GROUP}" \
  --vm-name "${AD_DC2_NAME}" \
  --name "disk-${AD_DC2_NAME}-ntds" \
  --new \
  --size-gb 32 \
  --sku Premium_LRS \
  --output none

# Meter NICs al backend pool del load balancer
NIC1_ID=$(az vm show -g "${RESOURCE_GROUP}" -n "${AD_DC1_NAME}" --query "networkProfile.networkInterfaces[0].id" -o tsv)
NIC2_ID=$(az vm show -g "${RESOURCE_GROUP}" -n "${AD_DC2_NAME}" --query "networkProfile.networkInterfaces[0].id" -o tsv)

NIC1_NAME=$(echo "$NIC1_ID" | awk -F'/' '{print $NF}')
NIC2_NAME=$(echo "$NIC2_ID" | awk -F'/' '{print $NF}')

az network nic ip-config address-pool add \
  --resource-group "${RESOURCE_GROUP}" \
  --nic-name "${NIC1_NAME}" \
  --ip-config-name "ipconfig1" \
  --lb-name "${AD_ILB_NAME}" \
  --address-pool "ad-backend-pool" \
  --output none

az network nic ip-config address-pool add \
  --resource-group "${RESOURCE_GROUP}" \
  --nic-name "${NIC2_NAME}" \
  --ip-config-name "ipconfig1" \
  --lb-name "${AD_ILB_NAME}" \
  --address-pool "ad-backend-pool" \
  --output none

