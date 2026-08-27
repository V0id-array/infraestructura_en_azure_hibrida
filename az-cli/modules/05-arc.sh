#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.env"

echo "[05-arc] Configurando DCR..."

LAW_ID=$(az monitor log-analytics workspace show \
  --resource-group "${RESOURCE_GROUP}" \
  --workspace-name "${LAW_NAME}" \
  --query id -o tsv 2>/dev/null || true)

DCR_NAME="dcr-windows-servers-${PROJECT_NAME}"

if [[ -n "$LAW_ID" ]]; then
  az monitor data-collection rule create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${DCR_NAME}" \
    --location "${LOCATION}" \
    --kind "Windows" \
    --log-analytics "[{resource-id:'${LAW_ID}',name:'central-workspace'}]" \
    --tags ${TAGS} \
    --output none 2>/dev/null || true
fi

ARC_SCRIPT="${SCRIPT_DIR}/../scripts/onboard-arc-template.ps1"
mkdir -p "${SCRIPT_DIR}/../scripts"

cat <<'EOF' > "${ARC_SCRIPT}"
Param (
    [Parameter(Mandatory=$true)][string]$ServicePrincipalClientId,
    [Parameter(Mandatory=$true)][string]$ServicePrincipalSecret,
    [Parameter(Mandatory=$true)][string]$TenantId,
    [Parameter(Mandatory=$true)][string]$SubscriptionId,
    [Parameter(Mandatory=$true)][string]$ResourceGroup,
    [Parameter(Mandatory=$false)][string]$Location = "westeurope"
)

Invoke-WebRequest -Uri "https://aka.ms/AzureConnectedMachineAgent" -OutFile "AzureConnectedMachineAgent.msi"
msiexec /i AzureConnectedMachineAgent.msi /qn

& "$env:ProgramFiles\AzureConnectedMachineAgent\azcmagent.exe" connect `
  --service-principal-id $ServicePrincipalClientId `
  --service-principal-secret $ServicePrincipalSecret `
  --tenant-id $TenantId `
  --subscription-id $SubscriptionId `
  --resource-group $ResourceGroup `
  --location $Location `
  --tags "Proyecto=empresa-az","Entorno=prod"
EOF

