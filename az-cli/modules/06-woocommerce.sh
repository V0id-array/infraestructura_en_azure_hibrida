#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.env"

echo "[06-woocommerce] Creando Container Registry..."
az acr create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${ACR_NAME}" \
  --sku Basic \
  --admin-enabled true \
  --location "${LOCATION}" \
  --tags ${TAGS} \
  --output none

echo "[06-woocommerce] Creando MySQL Flexible Server..."
az mysql flexible-server create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${MYSQL_SERVER_NAME}" \
  --location "${LOCATION}" \
  --admin-user "${MYSQL_ADMIN_USER}" \
  --admin-password "${MYSQL_ADMIN_PASS}" \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --storage-size 32 \
  --vnet "${WOO_VNET_NAME}" \
  --subnet "${WOO_SNET_DB_NAME}" \
  --tags ${TAGS} \
  --output none 2>/dev/null || true

echo "[06-woocommerce] Creando Redis Cache..."
az redis create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${REDIS_NAME}" \
  --location "${LOCATION}" \
  --sku Basic \
  --vm-size c0 \
  --tags ${TAGS} \
  --output none 2>/dev/null || true

echo "[06-woocommerce] Desplegando AKS..."
SUBNET_AKS_ID=$(az network vnet subnet show \
  --resource-group "${RESOURCE_GROUP}" \
  --vnet-name "${WOO_VNET_NAME}" \
  --name "${WOO_SNET_AKS_NAME}" \
  --query id -o tsv)

LAW_ID=$(az monitor log-analytics workspace show \
  --resource-group "${RESOURCE_GROUP}" \
  --workspace-name "${LAW_NAME}" \
  --query id -o tsv 2>/dev/null || true)

az aks create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${AKS_CLUSTER_NAME}" \
  --location "${LOCATION}" \
  --node-count "${AKS_NODE_COUNT}" \
  --node-vm-size "${AKS_VM_SIZE}" \
  --vnet-subnet-id "${SUBNET_AKS_ID}" \
  --attach-acr "${ACR_NAME}" \
  --enable-managed-identity \
  --enable-addons monitoring \
  --workspace-resource-id "${LAW_ID}" \
  --generate-ssh-keys \
  --tags ${TAGS} \
  --output none

