#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.env"

echo "[07-backup] Creando Recovery Services Vault..."
az backup vault create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${RSV_NAME}" \
  --location "${LOCATION}" \
  --tags ${TAGS} \
  --output none

az backup vault backup-properties set \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${RSV_NAME}" \
  --backup-storage-redundancy GeoRedundant \
  --output none 2>/dev/null || true

# Backup para las VMs de AD
DC1_ID=$(az vm show -g "${RESOURCE_GROUP}" -n "${AD_DC1_NAME}" --query id -o tsv 2>/dev/null || true)
DC2_ID=$(az vm show -g "${RESOURCE_GROUP}" -n "${AD_DC2_NAME}" --query id -o tsv 2>/dev/null || true)

if [[ -n "$DC1_ID" ]]; then
  az backup protection enable-for-vm \
    --resource-group "${RESOURCE_GROUP}" \
    --vault-name "${RSV_NAME}" \
    --vm "${DC1_ID}" \
    --policy-name "DefaultPolicy" \
    --output none 2>/dev/null || true
fi

if [[ -n "$DC2_ID" ]]; then
  az backup protection enable-for-vm \
    --resource-group "${RESOURCE_GROUP}" \
    --vault-name "${RSV_NAME}" \
    --vm "${DC2_ID}" \
    --policy-name "DefaultPolicy" \
    --output none 2>/dev/null || true
fi

# Backup para el file share
az backup protection enable-for-azurefileshare \
  --resource-group "${RESOURCE_GROUP}" \
  --vault-name "${RSV_NAME}" \
  --policy-name "SampleAzureFileSharePolicy" \
  --storage-account "${STORAGE_ACCOUNT_NAME}" \
  --azure-file-share "${FILE_SHARE_NAME}" \
  --output none 2>/dev/null || true

