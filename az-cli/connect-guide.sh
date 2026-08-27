#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.env"

echo "Comandos de acceso rápido (${RESOURCE_GROUP}):"
echo ""

echo "1. Active Directory (RDP / Bastion)"
echo "   az network bastion rdp --resource-group ${RESOURCE_GROUP} --target-resource-id \$(az vm show -g ${RESOURCE_GROUP} -n ${AD_DC1_NAME} --query id -o tsv)"
echo "   IP DC1: 10.0.4.4 | IP DC2: 10.0.4.5 | User: ${AD_ADMIN_USER}@${AD_DOMAIN_NAME}"
echo ""

echo "2. AKS (WooCommerce)"
echo "   az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${AKS_CLUSTER_NAME}"
echo "   kubectl get nodes"
echo ""

echo "3. Key Vault"
echo "   az keyvault secret list --vault-name ${KV_NAME} -o table"
echo "   az keyvault secret show --vault-name ${KV_NAME} --name ad-admin-password --query value -o tsv"
echo ""

echo "4. Azure File Share (SMB)"
echo "   ST_KEY=\$(az storage account keys list -g ${RESOURCE_GROUP} -n ${STORAGE_ACCOUNT_NAME} --query '[0].value' -o tsv)"
echo "   sudo mount -t cifs //${STORAGE_ACCOUNT_NAME}.file.core.windows.net/${FILE_SHARE_NAME} /mnt/share-corporate -o username=${STORAGE_ACCOUNT_NAME},password=\$ST_KEY,dir_mode=0777,file_mode=0777,serverino"
echo ""

echo "5. MySQL Flexible Server"
echo "   mysql -h ${MYSQL_SERVER_NAME}.mysql.database.azure.com -u ${MYSQL_ADMIN_USER} -p'${MYSQL_ADMIN_PASS}'"
echo ""

echo "6. Log Analytics"
echo "   LAW_ID=\$(az monitor log-analytics workspace show -g ${RESOURCE_GROUP} -n ${LAW_NAME} --query id -o tsv)"
echo "   az monitor log-analytics query --workspace \$LAW_ID --analytics-query \"Heartbeat | summarize count() by Computer\""

