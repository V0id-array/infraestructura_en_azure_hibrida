#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check_resource() {
    local NAME="$1"
    local CMD="$2"
    local EXPECTED="$3"

    printf "  %-30s " "${NAME}"
    RESULT=$(eval "${CMD}" 2>/dev/null || echo "ERROR")

    if [[ "${RESULT}" == *"${EXPECTED}"* ]]; then
        echo "OK"
        PASS=$((PASS + 1))
    else
        echo "FAIL (obtenido: ${RESULT})"
        FAIL=$((FAIL + 1))
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "${SCRIPT_DIR}")/terraform"

if command -v terraform &> /dev/null && [[ -d "${TERRAFORM_DIR}/.terraform" ]]; then
    cd "${TERRAFORM_DIR}"
    RG_NAME=$(terraform output -raw resource_group_name 2>/dev/null || echo "")
else
    read -rp "Nombre del Resource Group: " RG_NAME
fi

if [[ -z "${RG_NAME}" ]]; then
    echo "No se pudo determinar el Resource Group."
    exit 1
fi

echo "Validando recursos en ${RG_NAME}..."

# Networking
check_resource "VNet Hub" "az network vnet show -g ${RG_NAME} -n vnet-hub-westeurope --query provisioningState -o tsv" "Succeeded"
check_resource "VNet WooCommerce" "az network vnet show -g ${RG_NAME} -n vnet-woocommerce-westeurope --query provisioningState -o tsv" "Succeeded"
check_resource "VNet Corporate" "az network vnet show -g ${RG_NAME} -n vnet-corporate-westeurope --query provisioningState -o tsv" "Succeeded"
check_resource "Azure Firewall" "az network firewall show -g ${RG_NAME} -n fw-hub-enterprise-prod --query provisioningState -o tsv" "Succeeded"
check_resource "VPN Gateway" "az network vnet-gateway show -g ${RG_NAME} -n vpngw-hub-enterprise-prod --query provisioningState -o tsv" "Succeeded"
check_resource "Azure Bastion" "az network bastion show -g ${RG_NAME} -n bastion-hub-enterprise-prod --query provisioningState -o tsv" "Succeeded"

# Security & Monitoring
check_resource "Log Analytics" "az monitor log-analytics workspace show -g ${RG_NAME} -n law-central-enterprise-prod --query provisioningState -o tsv" "Succeeded"
check_resource "Key Vault" "az keyvault list -g ${RG_NAME} --query [0].properties.provisioningState -o tsv" "Succeeded"

# Storage
check_resource "Storage Account" "az storage account list -g ${RG_NAME} --query \"[?contains(name,'stcorpfiles')].provisioningState\" -o tsv" "Succeeded"

# WooCommerce
check_resource "AKS Cluster" "az aks show -g ${RG_NAME} -n aks-woo-enterprise-prod --query provisioningState -o tsv" "Succeeded"
check_resource "MySQL Flexible Server" "az mysql flexible-server show -g ${RG_NAME} -n mysql-woo-enterprise-prod --query state -o tsv" "Ready"
check_resource "Redis Cache" "az redis show -g ${RG_NAME} -n redis-woo-enterprise-prod --query provisioningState -o tsv" "Succeeded"

echo ""
echo "Resultados: ${PASS} OK, ${FAIL} fallos"
if [[ ${FAIL} -gt 0 ]]; then
    exit 1
fi

