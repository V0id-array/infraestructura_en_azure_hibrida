#!/usr/bin/env bash
set -euo pipefail

LOCATION="westeurope"
PREFIX="tfstate"
RESOURCE_GROUP_NAME="rg-terraform-backend"
CONTAINER_NAME="tfstate"
LOCK_NAME="lock-terraform-backend"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --location) LOCATION="$2"; shift 2 ;;
        --prefix)   PREFIX="$2"; shift 2 ;;
        *) echo "Uso: $0 [--location <region>] [--prefix <prefijo>]"; exit 1 ;;
    esac
done

RANDOM_SUFFIX=$(head -c 500 /dev/urandom | tr -dc 'a-z0-9' | cut -c 1-8)
STORAGE_ACCOUNT_NAME="st${PREFIX}${RANDOM_SUFFIX}"
if [[ ${#STORAGE_ACCOUNT_NAME} -gt 24 ]]; then
    STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME:0:24}"
fi

if ! az account show &> /dev/null; then
    az login
fi

echo "Creando resource group ${RESOURCE_GROUP_NAME} en ${LOCATION}..."
if ! az group show --name "${RESOURCE_GROUP_NAME}" &> /dev/null; then
    az group create \
        --name "${RESOURCE_GROUP_NAME}" \
        --location "${LOCATION}" \
        --output none
fi

echo "Creando storage account ${STORAGE_ACCOUNT_NAME}..."
if ! az storage account show --name "${STORAGE_ACCOUNT_NAME}" --resource-group "${RESOURCE_GROUP_NAME}" &> /dev/null; then
    az storage account create \
        --name "${STORAGE_ACCOUNT_NAME}" \
        --resource-group "${RESOURCE_GROUP_NAME}" \
        --location "${LOCATION}" \
        --sku "Standard_LRS" \
        --kind "StorageV2" \
        --access-tier "Hot" \
        --min-tls-version "TLS1_2" \
        --allow-blob-public-access false \
        --https-only true \
        --output none

    # Versionado para poder recuperar estados previos si se corrompe el tfstate
    az storage account blob-service-properties update \
        --account-name "${STORAGE_ACCOUNT_NAME}" \
        --resource-group "${RESOURCE_GROUP_NAME}" \
        --enable-versioning true \
        --output none
fi

STORAGE_KEY=$(az storage account keys list \
    --account-name "${STORAGE_ACCOUNT_NAME}" \
    --resource-group "${RESOURCE_GROUP_NAME}" \
    --query '[0].value' -o tsv)

echo "Creando blob container ${CONTAINER_NAME}..."
if ! az storage container show --name "${CONTAINER_NAME}" --account-name "${STORAGE_ACCOUNT_NAME}" --account-key "${STORAGE_KEY}" &> /dev/null; then
    az storage container create \
        --name "${CONTAINER_NAME}" \
        --account-name "${STORAGE_ACCOUNT_NAME}" \
        --account-key "${STORAGE_KEY}" \
        --output none
fi

# Evita que alguien borre accidentalmente el RG del estado
if ! az lock show --name "${LOCK_NAME}" --resource-group "${RESOURCE_GROUP_NAME}" &> /dev/null; then
    az lock create \
        --name "${LOCK_NAME}" \
        --resource-group "${RESOURCE_GROUP_NAME}" \
        --lock-type CanNotDelete \
        --output none
fi

CONFIG_FILE="$(dirname "$0")/../.backend-config"
cat > "${CONFIG_FILE}" <<EOF
BACKEND_RESOURCE_GROUP="${RESOURCE_GROUP_NAME}"
BACKEND_STORAGE_ACCOUNT="${STORAGE_ACCOUNT_NAME}"
BACKEND_CONTAINER="${CONTAINER_NAME}"
BACKEND_LOCATION="${LOCATION}"
BACKEND_STATE_KEY="infraestructura.tfstate"
EOF

echo "Backend configurado. Datos guardados en ${CONFIG_FILE}"

