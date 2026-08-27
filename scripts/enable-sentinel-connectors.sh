#!/usr/bin/env bash
set -euo pipefail

if ! az account show &> /dev/null; then
    az login
fi

SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)
TENANT_ID=$(az account show --query "tenantId" -o tsv)

WORKSPACE_NAME=$(az monitor log-analytics workspace list --query "[?contains(name, 'law-central')].name | [0]" -o tsv || echo "")
if [[ -z "${WORKSPACE_NAME}" ]]; then
    echo "No se encontro el workspace de Log Analytics."
    exit 1
fi

RESOURCE_GROUP=$(az monitor log-analytics workspace list --query "[?name=='${WORKSPACE_NAME}'].resourceGroup | [0]" -o tsv)

# Requiere rol Security Admin en la suscripcion
echo "Habilitando conector Defender for Cloud..."
az sentinel data-connector create \
  --resource-group "${RESOURCE_GROUP}" \
  --workspace-name "${WORKSPACE_NAME}" \
  --data-connector-id "connector-defender-cloud" \
  --mdfc-data-connector '{"kind":"MicrosoftDefenderForCloud","properties":{"subscriptionId":"'"${SUBSCRIPTION_ID}"'","dataTypes":{"alerts":{"state":"Enabled"}}}}' &> /dev/null || \
  echo "Aviso: no se pudo habilitar Defender for Cloud (faltan permisos)."

# Requiere permisos en Tenant (Global Reader / Security Admin)
echo "Habilitando conector Entra ID..."
az sentinel data-connector create \
  --resource-group "${RESOURCE_GROUP}" \
  --workspace-name "${WORKSPACE_NAME}" \
  --data-connector-id "connector-entra-id" \
  --aad-data-connector '{"kind":"AzureActiveDirectory","properties":{"tenantId":"'"${TENANT_ID}"'","dataTypes":{"alerts":{"state":"Enabled"}}}}' &> /dev/null || \
  echo "Aviso: no se pudo habilitar Entra ID (faltan permisos a nivel tenant)."

