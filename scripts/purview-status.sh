#!/usr/bin/env bash
set -eo pipefail

PURVIEW_ACCOUNT="${PURVIEW_ACCOUNT:-purview-corp-ggm82e}"
ENDPOINT="https://${PURVIEW_ACCOUNT}.purview.azure.com"

echo "Purview: ${PURVIEW_ACCOUNT}"


python3 -c '
import json, subprocess, urllib.request

try:
    token = subprocess.check_output(["az", "account", "get-access-token", "--resource", "https://purview.azure.net", "--query", "accessToken", "-o", "tsv"]).decode().strip()
except Exception as e:
    print(f"Error obteniendo token de Azure CLI: {e}")
    exit(1)

headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
base_url = "'"${ENDPOINT}"'"

def get_data(path):
    req = urllib.request.Request(f"{base_url}{path}", headers=headers)
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode())
    except Exception as e:
        return {"error": str(e)}

ds_data = get_data("/scan/datasources?api-version=2022-07-01-preview")
print("\n--- 1. FUENTES DE DATOS REGISTRADAS ---")
sources = ds_data.get("value", [])
for ds in sources:
    name = ds.get("name")
    kind = ds.get("kind")
    print(f"  • ID: {name} | Tipo: {kind}")

print("\n--- 2. ESTADO DE ESCANEOS Y EJECUCIONES ---")
for ds in sources:
    ds_name = ds.get("name")
    scans_data = get_data(f"/scan/datasources/{ds_name}/scans?api-version=2022-07-01-preview")
    for scan in scans_data.get("value", []):
        scan_name = scan.get("name")
        runs_data = get_data(f"/scan/datasources/{ds_name}/scans/{scan_name}/runs?api-version=2022-07-01-preview")
        runs = runs_data.get("value", [])
        if runs:
            latest = runs[0]
            status = latest.get("status")
            level = latest.get("scanLevelType")
            run_type = latest.get("runType")
            start = latest.get("startTime")
            disc = latest.get("assetsDiscovered")
            classif = latest.get("assetsClassified")
            print(f"  - Escaneo: {scan_name} ({ds_name})")
            print(f"    Estado:        {status}")
            print(f"    Nivel:         {level} ({run_type})")
            print(f"    Inicio:        {start}")
            print(f"    Descubiertos:  {disc} archivos")
            print(f"    Clasificados:  {classif} archivos con datos sensibles")
        else:
            print(f"  - Escaneo: {scan_name} (Sin ejecuciones)")
'

