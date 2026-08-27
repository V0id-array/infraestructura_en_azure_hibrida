#!/usr/bin/env bash
set -euo pipefail

# Comprobar azure cli
if ! command -v az &> /dev/null; then
    echo "Azure CLI no encontrado. Instalando..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

# Comprobar login
if ! az account show &> /dev/null; then
    az login
fi

echo "Suscripcion activa: $(az account show --query name -o tsv)"

# Evitar prompts interactivos al usar extensiones
az config set extension.use_dynamic_install=yes_without_prompt

# Purview y StorageSync suelen requerir registro explicito previo
for provider in "Microsoft.Purview" "Microsoft.StorageSync"; do
    echo "Registrando ${provider}..."
    az provider register --namespace "${provider}"
done

# SP necesario para los role assignments de Azure File Sync
STORAGE_SYNC_SP_ID=$(az ad sp list --display-name "Microsoft.StorageSync" --query "[0].id" -o tsv || true)
if [[ -n "${STORAGE_SYNC_SP_ID}" ]]; then
    echo "StorageSync SP ID: ${STORAGE_SYNC_SP_ID}"
fi

