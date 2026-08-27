#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.env"

LOG_DIR="${SCRIPT_DIR}/../logs/az-cli-modules"
mkdir -p "${LOG_DIR}"

if ! az account show &> /dev/null; then
    az login
fi

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

az group create --name "${RESOURCE_GROUP}" --location "${LOCATION}" --tags ${TAGS} --output none

# Fase 1: Red y Seguridad
bash "${SCRIPT_DIR}/modules/01-networking.sh" > "${LOG_DIR}/01-networking.log" 2>&1 &
PID_NET=$!

bash "${SCRIPT_DIR}/modules/02-security.sh" > "${LOG_DIR}/02-security.log" 2>&1 &
PID_SEC=$!

wait $PID_NET
wait $PID_SEC

# Fase 2: Cargas de trabajo
bash "${SCRIPT_DIR}/modules/03-corporate-storage.sh" > "${LOG_DIR}/03-corporate-storage.log" 2>&1 &
PID_STG=$!

bash "${SCRIPT_DIR}/modules/04-active-directory.sh" > "${LOG_DIR}/04-active-directory.log" 2>&1 &
PID_AD=$!

bash "${SCRIPT_DIR}/modules/05-arc.sh" > "${LOG_DIR}/05-arc.log" 2>&1 &
PID_ARC=$!

bash "${SCRIPT_DIR}/modules/06-woocommerce.sh" > "${LOG_DIR}/06-woocommerce.log" 2>&1 &
PID_WOO=$!

wait $PID_STG
wait $PID_AD
wait $PID_ARC
wait $PID_WOO

# Fase 3: Backup (necesita que las VMs y el storage existan)
bash "${SCRIPT_DIR}/modules/07-backup.sh" > "${LOG_DIR}/07-backup.log" 2>&1

echo "Despliegue paralelo completado. Logs en ${LOG_DIR}/"

