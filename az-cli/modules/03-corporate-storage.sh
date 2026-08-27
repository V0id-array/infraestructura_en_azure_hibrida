#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.env"

echo "[03-corporate-storage] Creando Storage Account ${STORAGE_ACCOUNT_NAME}..."
az storage account create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${STORAGE_ACCOUNT_NAME}" \
  --location "${LOCATION}" \
  --sku Standard_GRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --tags ${TAGS} \
  --output none

STORAGE_KEY=$(az storage account keys list \
  --resource-group "${RESOURCE_GROUP}" \
  --account-name "${STORAGE_ACCOUNT_NAME}" \
  --query "[0].value" -o tsv)

echo "[03-corporate-storage] Creando File Share..."
az storage share create \
  --account-name "${STORAGE_ACCOUNT_NAME}" \
  --account-key "${STORAGE_KEY}" \
  --name "${FILE_SHARE_NAME}" \
  --quota 1024 \
  --output none

echo "[03-corporate-storage] Creando Private Endpoint..."
STORAGE_ID=$(az storage account show --resource-group "${RESOURCE_GROUP}" --name "${STORAGE_ACCOUNT_NAME}" --query id -o tsv)
SUBNET_STORAGE_ID=$(az network vnet subnet show --resource-group "${RESOURCE_GROUP}" --vnet-name "${CORP_VNET_NAME}" --name "${CORP_SNET_STORAGE_NAME}" --query id -o tsv)

az network private-endpoint create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "pe-storage-corp" \
  --vnet-name "${CORP_VNET_NAME}" \
  --subnet "${SUBNET_STORAGE_ID}" \
  --private-connection-resource-id "${STORAGE_ID}" \
  --group-id "file" \
  --connection-name "conn-storage-corp" \
  --location "${LOCATION}" \
  --tags ${TAGS} \
  --output none

# Purview puede fallar si el proveedor no termino de registrarse
az purview account create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${PURVIEW_ACCOUNT_NAME}" \
  --location "${LOCATION}" \
  --tags ${TAGS} \
  --output none 2>/dev/null || true

