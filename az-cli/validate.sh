#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.env"

echo "Recursos en ${RESOURCE_GROUP}:"

echo "--- VNets ---"
az network vnet list -g "${RESOURCE_GROUP}" --query "[].{Nombre:name, Rango:addressSpace.addressPrefixes[0], Ubicacion:location}" -o table

echo "--- Seguridad y logs ---"
az monitor log-analytics workspace list -g "${RESOURCE_GROUP}" --query "[].{LAW:name, RetencionDias:retentionInDays}" -o table
az keyvault list -g "${RESOURCE_GROUP}" --query "[].{KeyVault:name, VaultURI:properties.vaultUri}" -o table

echo "--- Storage ---"
az storage account list -g "${RESOURCE_GROUP}" --query "[].{Nombre:name, SKU:sku.name, Kind:kind}" -o table

echo "--- VMs (DCs) ---"
az vm list -g "${RESOURCE_GROUP}" --query "[].{VM:name, Estado:provisioningState, Size:hardwareProfile.vmSize, Zona:zones[0]}" -o table

echo "--- AKS ---"
az aks list -g "${RESOURCE_GROUP}" --query "[].{Cluster:name, K8sVersion:kubernetesVersion, Nodos:agentPoolProfiles[0].count}" -o table

echo "--- Backup Vault ---"
az backup vault list -g "${RESOURCE_GROUP}" --query "[].{Vault:name, Ubicacion:location}" -o table

