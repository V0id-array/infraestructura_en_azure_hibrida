#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.env"

LOG_DIR="${SCRIPT_DIR}/../logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/az-cli-deploy.log"

exec > >(tee -a "${LOG_FILE}") 2>&1

if ! az account show &> /dev/null; then
    az login
fi

echo "Iniciando despliegue con az cli..."

az config set extension.use_dynamic_install=yes_without_prompt --output none 2>/dev/null || true

PROVIDERS=(
  "Microsoft.Network"
  "Microsoft.KeyVault"
  "Microsoft.Compute"
  "Microsoft.Storage"
  "Microsoft.ContainerService"
  "Microsoft.DBforMySQL"
  "Microsoft.Cache"
  "Microsoft.RecoveryServices"
  "Microsoft.OperationalInsights"
  "Microsoft.OperationsManagement"
  "Microsoft.Purview"
  "Microsoft.StorageSync"
)

for provider in "${PROVIDERS[@]}"; do
  az provider register --namespace "${provider}" --wait --output none 2>/dev/null || true
done

az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --tags ${TAGS} \
  --output none

bash "${SCRIPT_DIR}/modules/01-networking.sh"
bash "${SCRIPT_DIR}/modules/02-security.sh"
bash "${SCRIPT_DIR}/modules/03-corporate-storage.sh"
bash "${SCRIPT_DIR}/modules/04-active-directory.sh"
bash "${SCRIPT_DIR}/modules/05-arc.sh"
bash "${SCRIPT_DIR}/modules/06-woocommerce.sh"
bash "${SCRIPT_DIR}/modules/07-backup.sh"

echo "Despliegue finalizado. Log en ${LOG_FILE}"

