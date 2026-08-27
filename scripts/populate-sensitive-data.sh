#!/usr/bin/env bash
set -euo pipefail

RESOURCE_GROUP="${RESOURCE_GROUP:-rg-corporate-purview-prod}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-stcorpfilesggm82e}"
SHARE_NAME="${SHARE_NAME:-share-corporate}"

echo "Obteniendo storage account key..."
STORAGE_KEY=$(az storage account keys list \
    --resource-group "${RESOURCE_GROUP}" \
    --account-name "${STORAGE_ACCOUNT}" \
    --query "[0].value" -o tsv)

if [[ -z "${STORAGE_KEY}" ]]; then
    echo "Error: no se pudo obtener la clave de la cuenta de storage."
    exit 1
fi

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "${TEMP_DIR}"' EXIT

mkdir -p "${TEMP_DIR}/Finanzas"
cat <<'EOF' > "${TEMP_DIR}/Finanzas/tarjetas_credito_clientes_2026.csv"
ID_Cliente,Nombre_Titular,Numero_Tarjeta,Fecha_Exp,CVV,IBAN_Asociado,Monto_Ultimo_Pago
CLI-1001,Carlos Mendoza Gomez,4532109845128901,08/28,431,ES9121000418401234567890,1450.50 EUR
CLI-1002,Elena Maria Torres,5412758934120987,11/27,892,ES6201821234567890123456,890.00 EUR
CLI-1003,Javier Ortiz Ruiz,4916234589012345,03/29,154,ES8000491825301234567891,3200.75 EUR
CLI-1004,Sofia Benitez Castro,5241908712345678,05/26,673,ES1420381029384756102938,450.20 EUR
CLI-1005,Miguel Angel Navarro,4024007123458912,12/28,310,ES3000810192837465019283,2100.00 EUR
EOF

cat <<'EOF' > "${TEMP_DIR}/Finanzas/facturacion_y_cuentas_bancarias.csv"
Factura_ID,Empresa_Cliente,CIF_Empresa,IBAN_Cobro,BIC_SWIFT,Importe_Total_EUR
FAC-2026-001,Tecnologias Avanzadas S.L.,B87654321,ES9100491500051234567892,BSCHESMMXXX,45000.00
FAC-2026-002,Logistica Global España S.A.,A12345678,ES6221001234567890123457,CAIXESBBXXX,128500.50
FAC-2026-003,Consultoria Iberica S.L.,B43218765,ES8001829999110123456789,BBVAESMMXXX,18200.00
EOF

mkdir -p "${TEMP_DIR}/RRHH"
cat <<'EOF' > "${TEMP_DIR}/RRHH/nominas_y_datos_empleados.csv"
ID_Empleado,Nombre_Completo,DNI_NIF,Num_Seguridad_Social,IBAN_Nomina,Salario_Bruto_Anual,Email_Personal
EMP-01,Laura Fernandez Vidal,48592014Z,281234567840,ES9121000418409988776655,42000.00,laura.fdez.personal@gmail.com
EMP-02,Roberto Sanchez Martin,12345678Z,289876543210,ES6201821234561122334455,38500.00,roberto.sanchez88@hotmail.com
EMP-03,Ana Belen Garcia Lopez,87654321X,285566778899,ES8000491825305544332211,55000.00,ana.garcia.bio@outlook.com
EMP-04,David Jimenez Vega,71982345M,284433221100,ES1420381029386677889900,31000.00,david.jv.91@gmail.com
EOF

cat <<'EOF' > "${TEMP_DIR}/RRHH/expedientes_medicos_bajas.txt"
REGISTRO DE SALUD Y BAJAS LABORALES (CONFIDENCIAL - USO EXCLUSIVO RRHH)

Empleado: Laura Fernandez Vidal
DNI: 48592014Z
Diagnostico: Cervicalgia aguda y ansiedad laboral.
Periodo de Baja: 12/01/2026 al 02/02/2026.
Nº Colegiado Medico: 282849102.

Empleado: David Jimenez Vega
DNI: 71982345M
Diagnostico: Intervencion quirurgica traumatologica en rodilla derecha.
Periodo de Baja: 05/03/2026 al 15/04/2026.
EOF

mkdir -p "${TEMP_DIR}/Legal"
cat <<'EOF' > "${TEMP_DIR}/Legal/contrato_fusion_y_nda_confidencial.txt"
ACUERDO DE CONFIDENCIALIDAD Y FUSION (NDA)

De una parte, Don Alberto Pastor Gomez, con Pasaporte Espanol Nº AAA123456, en representacion de Enterprise Corporate S.A.
De otra parte, Dona Beatriz Ramos Saenz, con DNI Nº 53891024P, en representacion de TechPartner Europe B.V.

CLAUSULA PRIMERA: SECRETO INDUSTRIAL Y VALORACION
Valoracion de la adquisicion: 15.500.000 EUR. 
Cuenta en Luxemburgo IBAN LU280019400000000000.

CLAUSULA SEGUNDA: DATOS PROTEGIDOS DE ACCIONISTAS
Accionista Principal: Alejandro Vidal Serrano
DNI: 09876543Y | Pasaporte: BBB987654 | Participacion: 45%
EOF

mkdir -p "${TEMP_DIR}/IT"
cat <<'EOF' > "${TEMP_DIR}/IT/credenciales_servidores_produccion.json"
{
  "entorno": "Produccion",
  "base_de_datos_mysql": {
    "host": "mysql-woo-enterprise-prod.mysql.database.azure.com",
    "usuario": "woo_admin",
    "password_root": "MySQLSecurePassword2026!#",
    "connection_string": "Server=mysql-woo-enterprise-prod.mysql.database.azure.com;Port=3306;Database=woocommerce;Uid=woo_admin;Pwd=MySQLSecurePassword2026!#;SslMode=Preferred;"
  },
  "active_directory_admin": {
    "domain": "corp.enterprise.local",
    "admin_user": "azureadmin",
    "admin_password": "ADSecurePassword2026!#"
  },
  "api_keys_terceros": {
    "stripe_live_key": "mock_stripe_key_000000000000000000000000",
    "sendgrid_api_key": "mock_sendgrid_key_000000000000000000000000"
  }
}
EOF


mkdir -p "${TEMP_DIR}/Direccion"
cat <<'EOF' > "${TEMP_DIR}/Direccion/informe_estrategico_junta_directiva.md"
# INFORME ESTRATEGICO - CONFIDENCIAL

## 1. Miembros del Consejo de Administracion
* Presidente: Guillermo Soria Alarcon (DNI: 03124589K / Pasaporte: C30192837)
* Directora Financiera: Marta Gil Castrillo (DNI: 51902834L / IBAN: ES1200491500059988776655)

## 2. Proyeccion Financiera
* Resultado estimado: 4.850.000 EUR
* Reserva en Suiza: IBAN CH9300762011623852957
EOF

mkdir -p "${TEMP_DIR}/Operaciones"
cat <<'EOF' > "${TEMP_DIR}/Operaciones/proveedores_internacionales_logistica.csv"
ID_Proveedor,Razon_Social,VAT_Number,Pais,IBAN_Pago,SWIFT_Code
PROV-DE-01,EuroTrans Logistik GmbH,DE123456789,Alemania,DE89370400440532013000,COBADEFFXXX
PROV-FR-02,Transport France Express SAS,FR987654321,Francia,FR7630006000011234567890123,BNPAFRPPXXX
PROV-UK-03,Global Cargo UK Ltd,GB555666777,Reino Unido,GB29NWBK60161331926819,NWBKGB2LXXX
EOF

departments=("Finanzas" "RRHH" "Legal" "IT" "Direccion" "Operaciones")

for dept in "${departments[@]}"; do
    echo "Subiendo archivos de ${dept}..."
    
    az storage directory create \
        --account-name "${STORAGE_ACCOUNT}" \
        --account-key "${STORAGE_KEY}" \
        --share-name "${SHARE_NAME}" \
        --name "${dept}" \
        --output none

    for file in "${TEMP_DIR}/${dept}"/*; do
        filename=$(basename "${file}")
        az storage file upload \
            --account-name "${STORAGE_ACCOUNT}" \
            --account-key "${STORAGE_KEY}" \
            --share-name "${SHARE_NAME}" \
            --path "${dept}/${filename}" \
            --source "${file}" \
            --output none
    done
done

echo "Carga completada en ${STORAGE_ACCOUNT}/${SHARE_NAME}."

