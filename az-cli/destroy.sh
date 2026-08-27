#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.env"

read -rp "Eliminar el resource group ${RESOURCE_GROUP}? (escribe 'si' para confirmar): " CONFIRM
if [[ "$CONFIRM" != "si" ]]; then
    echo "Cancelado."
    exit 0
fi

echo "Eliminando ${RESOURCE_GROUP} en background..."
az group delete --name "${RESOURCE_GROUP}" --yes --no-wait

