#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.env"

echo "[02-security] Creando Log Analytics Workspace..."
az monitor log-analytics workspace create \
  --resource-group "${RESOURCE_GROUP}" \
  --workspace-name "${LAW_NAME}" \
  --location "${LOCATION}" \
  --retention-time 30 \
  --tags ${TAGS} \
  --output none

export LAW_ID=$(az monitor log-analytics workspace show \
  --resource-group "${RESOURCE_GROUP}" \
  --workspace-name "${LAW_NAME}" \
  --query id -o tsv)

# Habilitar Sentinel (puede fallar si no hay rol Owner en suscripcion)
az operationalinsights solution create \
  --resource-group "${RESOURCE_GROUP}" \
  --solution-type "SecurityInsights" \
  --workspace-resource-id "${LAW_ID}" \
  --output none 2>/dev/null || true

echo "[02-security] Creando Key Vault..."
az keyvault create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${KV_NAME}" \
  --location "${LOCATION}" \
  --enable-rbac-authorization false \
  --enabled-for-deployment true \
  --enabled-for-disk-encryption true \
  --enabled-for-template-deployment true \
  --tags ${TAGS} \
  --output none

# Asignar acceso al usuario actual para poder meter los passwords
CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || true)
if [[ -n "$CURRENT_USER_ID" ]]; then
  az keyvault set-policy \
    --name "${KV_NAME}" \
    --object-id "${CURRENT_USER_ID}" \
    --secret-permissions get list set delete \
    --output none 2>/dev/null || true
fi

az keyvault secret set --vault-name "${KV_NAME}" --name "ad-admin-password" --value "${AD_ADMIN_PASS}" --output none 2>/dev/null || true
az keyvault secret set --vault-name "${KV_NAME}" --name "mysql-admin-password" --value "${MYSQL_ADMIN_PASS}" --output none 2>/dev/null || true

