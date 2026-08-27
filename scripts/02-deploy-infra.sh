#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
TERRAFORM_DIR="${PROJECT_DIR}/terraform"
BACKEND_CONFIG="${PROJECT_DIR}/.backend-config"

AUTO_APPROVE=""
PLAN_ONLY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --auto-approve) AUTO_APPROVE="-auto-approve"; shift ;;
        --plan-only)    PLAN_ONLY=true; shift ;;
        *) echo "Uso: $0 [--auto-approve] [--plan-only]"; exit 1 ;;
    esac
done

if [[ ! -f "${BACKEND_CONFIG}" ]]; then
    echo "Falta .backend-config. Ejecutar antes scripts/01-init-backend.sh"
    exit 1
fi

source "${BACKEND_CONFIG}"

cd "${TERRAFORM_DIR}"

terraform init \
    -backend-config="resource_group_name=${BACKEND_RESOURCE_GROUP}" \
    -backend-config="storage_account_name=${BACKEND_STORAGE_ACCOUNT}" \
    -backend-config="container_name=${BACKEND_CONTAINER}" \
    -backend-config="key=${BACKEND_STATE_KEY}" \
    -reconfigure

terraform validate

if [[ "${PLAN_ONLY}" == "true" ]]; then
    terraform plan
    exit 0
fi

if [[ -n "${AUTO_APPROVE}" ]]; then
    terraform apply -auto-approve
else
    terraform apply
fi

