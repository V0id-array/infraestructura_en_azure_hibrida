# Registro de Progreso

Seguimiento de la implementacion. Detalles de arquitectura en [planning.md](planning.md).

---

## Registro de Actividad

### 2026-07-12

| Hora | Fase | Accion | Resultado |
|:---|:---|:---|:---|
| 10:39 | Fase 1 | Creacion inicial de la estructura | Completado |
| 10:51 | Fase 1 | Ajuste de arquitectura: Sentinel, Purview, Arc, AKS | Completado |
| 10:53 | Fase 2 | Script backend Terraform `scripts/01-init-backend.sh` | Completado |
| 10:54 | Fase 2 | Script PowerShell `scripts/01-init-backend.ps1` | Completado |
| 10:54 | Fase 3 | Archivos base Terraform (`providers.tf`, `variables.tf`, `main.tf`, `outputs.tf`) | Completado |
| 10:55 | Fase 3 | Modulo `modules/networking/` | Completado |
| 10:57 | Fase 3 | Modulo `modules/security/` | Completado |
| 10:58 | Fase 3 | Modulo `modules/corporate-storage/` | Completado |
| 10:58 | Fase 3 | Modulo `modules/arc/` | Completado |
| 10:59 | Fase 3 | Modulo `modules/woocommerce/` | Completado |
| 11:00 | Fase 4 | Script onboarding `scripts/arc-onboard-windows.ps1` | Completado |
| 11:00 | Fase 4 | Script despliegue `scripts/02-deploy-infra.sh` | Completado |
| 11:01 | Fase 4 | Script validacion `scripts/03-validate-infra.sh` | Completado |
| 11:01 | Fase 1 | Separacion de docs planning y progress | Completado |
| 11:13 | Fase 6 | Revision de compatibilidad provider azurerm | Completado |
| 11:16 | Fase 6 | `terraform validate` exitoso | Completado |
| 11:16 | Fase 3 | Mapeo Active Directory (Windows Server HA) | Completado |
| 11:28 | Fase 3 | AD DCs en 2 zonas con ILB para DNS/LDAP | Completado |
| 11:31 | Fase 7 | Modulo `modules/backup/` | Completado |
| 11:35 | Fase 3 | WAF en Front Door modo Prevention | Completado |
| 12:30 | Fase 3 | Despliegue de Azure File Sync | Completado |

### 2026-07-13

| Hora | Fase | Accion | Resultado |
|:---|:---|:---|:---|
| 11:26 | Fase 2 | Generacion de `terraform/terraform.tfvars` | Completado |
| 11:28 | Fase 2 | Inicializacion backend remoto de Terraform | Completado |
| 11:29 | Fase 9 | Creacion de logs de bootstrap | Completado |
| 12:10 | Fase 9 | Correcciones de compatibilidad de tipos y recursos en TF | Completado |
| 12:15 | Fase 9 | Despliegue general | En progreso |

### 2026-07-31

| Hora | Fase | Accion | Resultado |
|:---|:---|:---|:---|
| 14:48 | Reestructuracion | Modulo CLI nativo en `az-cli/` con scripts Bash | Completado |
| 15:53 | Correccion az-cli | Permisos explícitos en Key Vault para usuario actual | Completado |
| 15:55 | Mejora az-cli | Registro de resource providers en `deploy.sh` | Completado |
| 16:20 | Correccion az-cli | Protocolo TCP en probe del LB de AD | Completado |
| 16:24 | Correccion az-cli | Semilla `.env_seed` para idempotencia | Completado |

---

## Estado de Fases

- [x] **Fase 1**: Planificacion y documentacion
- [x] **Fase 2**: Bootstrap backend Terraform
- [x] **Fase 3**: Modulos Terraform
- [x] **Fase 4**: Scripts de despliegue y validacion
- [x] **Fase 6**: Validacion de sintaxis Terraform
- [x] **Fase 7**: Configuracion de Backup
- [ ] **Fase 8**: Manifiestos de Kubernetes
- [ ] **Fase 9**: Despliegue en Azure
- [ ] **Fase 10**: Validacion final

---

## Incidencias y Correcciones

| # | Fecha | Descripcion | Resolucion |
|:---|:---|:---|:---|
| 1 | 2026-07-12 11:13 | Variable `hub_vnet_id` no usada en security | Eliminada |
| 2 | 2026-07-12 11:13 | Atributos incompatibles con azurerm 3.x | Adaptados al provider |
| 3 | 2026-07-12 11:13 | Version k8s fija | Convertida a variable `aks_kubernetes_version` |
| 4 | 2026-07-12 11:27 | Error en reglas de Load Balancer | `backend_address_pool_ids` en lista |
| 5 | 2026-07-12 11:30 | Tipo azurerm_backup_container incompatible | Cambiado a azurerm_backup_container_storage_account |
| 6 | 2026-07-13 12:05 | Computer name mayor a 15 caracteres | `computer_name` explicito recortado |
| 7 | 2026-07-13 12:05 | Error de permisos para policy assignments en suscripcion de lab | Politicas comentadas |
| 8 | 2026-07-13 12:05 | RSV bloqueado por directiva de inmutabilidad | Parametro `immutability = "Disabled"` |
| 9 | 2026-07-13 12:05 | Providers Purview y StorageSync sin registrar | `az provider register` previo |
| 10 | 2026-07-13 12:05 | SKU VpnGw1 no AZ descontinuado | Cambiado a `VpnGw1AZ` |
| 11 | 2026-07-13 12:05 | Longitud de nombre de Key Vault superior a 24 caracteres | Acortado patron de nombre |
| 12 | 2026-07-13 12:05 | Version de K8s no disponible en la region | Actualizado a version soportada |
| 13 | 2026-07-13 12:05 | WAF managed rules requiere Premium en Front Door | SKU actualizado a Premium |
| 14 | 2026-07-13 12:05 | Error 403 al crear share desde runner | `default_action = "Allow"` en storage network rules |
| 15 | 2026-07-13 12:05 | Error 401 en conectores de Sentinel por falta de permisos en Tenant | Conectores comentados |


