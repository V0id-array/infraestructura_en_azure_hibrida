#!/usr/bin/env bash
set -euo pipefail

RANDOM_SUFFIX="$(openssl rand -hex 3)"
RESOURCE_GROUP="rg-azure-free-tier"
LOCATION_PRIMARY="swedencentral"
KEY_VAULT_NAME="kv-free-${RANDOM_SUFFIX}"
VNET_NAME="vnet-sweden-free"
SUBNET_NAME="snet-sweden-free"
LB_NAME="lb-sweden-shared"
PUBLIC_IP_NAME="pip-sweden-shared"
ADMIN_USER="azureuser"

SQL_SERVER_NAME="sqlserver-free-${RANDOM_SUFFIX}"
SQL_DB_NAME="sqldb-free"
MYSQL_SERVER_NAME="mysql-free-${RANDOM_SUFFIX}"

if ! az account show > /dev/null 2>&1; then
    echo "Error: ejecuta az login antes de continuar."
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)

# Clave SSH
SSH_KEY_PATH="${HOME}/.ssh/id_rsa"
if [ ! -f "${SSH_KEY_PATH}" ]; then
    ssh-keygen -t rsa -b 2048 -f "${SSH_KEY_PATH}" -N ""
fi

ADMIN_PASSWORD=$(python3 -c "import secrets, string; alphabet = string.ascii_letters + string.digits + '!@#$%^&*()'; print(''.join(secrets.choice(alphabet) for _ in range(24)))")

echo "Creando resource group..."
az group create --name "${RESOURCE_GROUP}" --location "${LOCATION_PRIMARY}" -o table

echo "Creando Key Vault..."
az keyvault create \
  --name "${KEY_VAULT_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION_PRIMARY}" \
  -o table

USER_OBJECT_ID=$(az ad signed-in-user show --query "id" -o tsv 2>/dev/null || echo "")
if [ -n "${USER_OBJECT_ID}" ]; then
    az role assignment create \
      --role "Key Vault Secrets Officer" \
      --assignee "${USER_OBJECT_ID}" \
      --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.KeyVault/vaults/${KEY_VAULT_NAME}" \
      -o table || true
    sleep 10
fi

az keyvault secret set --vault-name "${KEY_VAULT_NAME}" --name "ssh-private-key" --file "${SSH_KEY_PATH}" -o none
az keyvault secret set --vault-name "${KEY_VAULT_NAME}" --name "ssh-public-key" --file "${SSH_KEY_PATH}.pub" -o none
az keyvault secret set --vault-name "${KEY_VAULT_NAME}" --name "admin-password" --value "${ADMIN_PASSWORD}" -o none

echo "Creando VNet..."
az network vnet create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${VNET_NAME}" \
  --location "${LOCATION_PRIMARY}" \
  --address-prefix 10.0.0.0/16 \
  --subnet-name "${SUBNET_NAME}" \
  --subnet-prefix 10.0.0.0/24 \
  -o table

az network vnet subnet update \
  --resource-group "${RESOURCE_GROUP}" \
  --vnet-name "${VNET_NAME}" \
  --name "${SUBNET_NAME}" \
  --service-endpoints Microsoft.Sql \
  -o table

echo "Creando balanceador e IP publica..."
az network public-ip create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${PUBLIC_IP_NAME}" \
  --location "${LOCATION_PRIMARY}" \
  --sku Standard \
  --allocation-method Static \
  -o table

SHARED_PUBLIC_IP=$(az network public-ip show -g "${RESOURCE_GROUP}" -n "${PUBLIC_IP_NAME}" --query "ipAddress" -o tsv)

az network lb create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${LB_NAME}" \
  --location "${LOCATION_PRIMARY}" \
  --sku Standard \
  --public-ip-address "${PUBLIC_IP_NAME}" \
  --frontend-ip-name fe-sweden-shared \
  --backend-pool-name be-sweden-shared \
  -o table

az network lb inbound-nat-rule create \
  --resource-group "${RESOURCE_GROUP}" \
  --lb-name "${LB_NAME}" \
  --name nat-ssh-b2pts \
  --protocol Tcp \
  --frontend-port 2222 \
  --backend-port 22 \
  --frontend-ip-name fe-sweden-shared \
  -o table

az network lb inbound-nat-rule create \
  --resource-group "${RESOURCE_GROUP}" \
  --lb-name "${LB_NAME}" \
  --name nat-ssh-b2ats \
  --protocol Tcp \
  --frontend-port 2223 \
  --backend-port 22 \
  --frontend-ip-name fe-sweden-shared \
  -o table

echo "Desplegando VMs..."
az vm create \
  --resource-group "${RESOURCE_GROUP}" \
  --name vm-b2pts-eu \
  --location "${LOCATION_PRIMARY}" \
  --image Canonical:ubuntu-24_04-lts:server-arm64:latest \
  --size Standard_B2pts_v2 \
  --vnet-name "${VNET_NAME}" \
  --subnet "${SUBNET_NAME}" \
  --admin-username "${ADMIN_USER}" \
  --ssh-key-values "${SSH_KEY_PATH}.pub" \
  --public-ip-address "" \
  -o table

az network nic ip-config inbound-nat-rule add \
  --resource-group "${RESOURCE_GROUP}" \
  --nic-name vm-b2pts-euVMNic \
  --ip-config-name ipconfigvm-b2pts-eu \
  --lb-name "${LB_NAME}" \
  --inbound-nat-rule nat-ssh-b2pts \
  -o table

az vm create \
  --resource-group "${RESOURCE_GROUP}" \
  --name vm-b2ats-linux \
  --location "${LOCATION_PRIMARY}" \
  --image Canonical:ubuntu-24_04-lts:server:latest \
  --size Standard_B2ats_v2 \
  --vnet-name "${VNET_NAME}" \
  --subnet "${SUBNET_NAME}" \
  --admin-username "${ADMIN_USER}" \
  --ssh-key-values "${SSH_KEY_PATH}.pub" \
  --public-ip-address "" \
  -o table

az network nic ip-config inbound-nat-rule add \
  --resource-group "${RESOURCE_GROUP}" \
  --nic-name vm-b2ats-linuxVMNic \
  --ip-config-name ipconfigvm-b2ats-linux \
  --lb-name "${LB_NAME}" \
  --inbound-nat-rule nat-ssh-b2ats \
  -o table

az network nsg rule create \
  --resource-group "${RESOURCE_GROUP}" \
  --nsg-name vm-b2pts-euNSG \
  --name allow-ssh-nat-ports \
  --priority 1010 \
  --destination-port-ranges 2222 2223 22 \
  --access Allow \
  --protocol Tcp \
  --direction Inbound \
  -o table || true

echo "Desplegando Azure SQL..."
az sql server create \
  --name "${SQL_SERVER_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION_PRIMARY}" \
  --admin-user "${ADMIN_USER}" \
  --admin-password "${ADMIN_PASSWORD}" \
  -o table

az sql db create \
  --resource-group "${RESOURCE_GROUP}" \
  --server "${SQL_SERVER_NAME}" \
  --name "${SQL_DB_NAME}" \
  --edition Standard \
  --service-objective S0 \
  -o table

az sql server vnet-rule create \
  --resource-group "${RESOURCE_GROUP}" \
  --server "${SQL_SERVER_NAME}" \
  --name vnet-rule-free \
  --vnet-name "${VNET_NAME}" \
  --subnet "${SUBNET_NAME}" \
  -o table

az sql server firewall-rule create \
  --resource-group "${RESOURCE_GROUP}" \
  --server "${SQL_SERVER_NAME}" \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0 \
  -o table

echo "Despliegue finalizado."
echo "IP publica: ${SHARED_PUBLIC_IP}"
echo "SSH VM1: ssh -p 2222 ${ADMIN_USER}@${SHARED_PUBLIC_IP}"
echo "SSH VM2: ssh -p 2223 ${ADMIN_USER}@${SHARED_PUBLIC_IP}"
echo "SQL Host: ${SQL_SERVER_NAME}.database.windows.net"

