# 00 - Inventario del Repositorio

**Fecha:** 2026-10-04  
**Estado:** Fase 0 completada (Auditoría y limpieza)

---

## Estructura actual del repositorio

```
infraestructura_en_azure_hibrida/
├── .gitignore
├── 00-prepare-env.sh
├── README.md
├── architecture_diagram.drawio
├── deploy-azure-free-tier-README.md
├── deploy-azure-free-tier.sh
├── planning.md
├── progress.md
├── az-cli/
│   ├── README.md
│   ├── config.env
│   ├── connect-guide.sh
│   ├── deploy-parallel.sh
│   ├── deploy.sh
│   ├── destroy.sh
│   ├── validate.sh
│   └── modules/
├── kubernetes/
│   ├── 01-secrets.yaml
│   ├── 02-configmap.yaml
│   ├── 03-pvc.yaml
│   ├── 04-wordpress.yaml
│   └── README.md
├── scripts/
│   ├── 01-init-backend.ps1
│   ├── 01-init-backend.sh
│   ├── 02-deploy-infra.sh
│   ├── 03-validate-infra.sh
│   ├── 04-join-storage-to-ad.ps1
│   ├── arc-onboard-windows.ps1
│   ├── enable-sentinel-connectors.sh
│   ├── env_vars.ps1
│   ├── env_vars.sh
│   ├── populate-sensitive-data.sh
│   └── purview-status.sh
├── terraform/
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfvars.example
│   ├── variables.tf
│   └── modules/
│       ├── active-directory/
│       ├── arc/
│       ├── backup/
│       ├── corporate-storage/
│       ├── networking/
│       ├── security/
│       └── woocommerce/
└── terraform-lean/
    ├── main.tf
    ├── outputs.tf
    ├── providers.tf
    └── variables.tf
```

---

## Inventario detallado por carpeta

### Raíz del repositorio

| Fichero | Tipo | Estado | Acción |
|:---|:---|:---|:---|
| `.gitignore` | Configuración | ✅ Mantener | Actualizar con entradas adicionales |
| `00-prepare-env.sh` | Script | ⚠️ Revisar | Integrar en runbook o archivar |
| `README.md` | Documentación | ⚠️ Reescribir | Convertir en portada corta |
| `architecture_diagram.drawio` | Diagrama | ✅ Mantener | Exportar a PNG/SVG para README |
| `deploy-azure-free-tier-README.md` | Documentación | ⚠️ Revisar | Integrar en runbook |
| `deploy-azure-free-tier.sh` | Script | ⚠️ Revisar | Integrar en runbook |
| `planning.md` | Documentación | ⚠️ Mover | Mover a `docs/planning.md` |
| `progress.md` | Documentación | ⚠️ Mover | Mover a `docs/progress.md` |

### `az-cli/`

| Fichero | Tipo | Estado | Acción |
|:---|:---|:---|:---|
| `README.md` | Documentación | ✅ Mantener | Revisar coherencia |
| `config.env` | Configuración | ⚠️ Auditar | Verificar que no hay secrets reales |
| `connect-guide.sh` | Script | ✅ Mantener | |
| `deploy-parallel.sh` | Script | ✅ Mantener | |
| `deploy.sh` | Script | ✅ Mantener | |
| `destroy.sh` | Script | ✅ Mantener | |
| `validate.sh` | Script | ✅ Mantener | |
| `modules/` | Scripts | ✅ Mantener | |

**Decisión:** Mantener como alternativa de despliegue sin Terraform.

### `kubernetes/`

| Fichero | Tipo | Estado | Acción |
|:---|:---|:---|:---|
| `01-secrets.yaml` | Manifiesto | ⚠️ Auditar | Verificar que no hay secrets reales |
| `02-configmap.yaml` | Manifiesto | ⚠️ Auditar | Verificar que no hay datos sensibles |
| `03-pvc.yaml` | Manifiesto | ✅ Mantener | |
| `04-wordpress.yaml` | Manifiesto | ✅ Mantener | |
| `README.md` | Documentación | ✅ Mantener | |

**Decisión:** Mantener. Auditar secrets y ConfigMaps.

### `scripts/`

| Fichero | Tipo | Estado | Acción |
|:---|:---|:---|:---|
| `01-init-backend.ps1` | Script | ✅ Mantener | |
| `01-init-backend.sh` | Script | ✅ Mantener | |
| `02-deploy-infra.sh` | Script | ✅ Mantener | |
| `03-validate-infra.sh` | Script | ✅ Mantener | |
| `04-join-storage-to-ad.ps1` | Script | ✅ Mantener | |
| `arc-onboard-windows.ps1` | Script | ✅ Mantener | |
| `enable-sentinel-connectors.sh` | Script | ✅ Mantener | |
| `env_vars.ps1` | Script | ⚠️ Auditar | Verificar que no hay secrets |
| `env_vars.sh` | Script | ⚠️ Auditar | Verificar que no hay secrets |
| `populate-sensitive-data.sh` | Script | ⚠️ Auditar | Verificar que es solo sintético |
| `purview-status.sh` | Script | ✅ Mantener | |

**Decisión:** Mantener todos. Auditar scripts de variables de entorno.

### `terraform/`

| Fichero | Tipo | Estado | Acción |
|:---|:---|:---|:---|
| `main.tf` | Terraform | ✅ Mantener | |
| `outputs.tf` | Terraform | ✅ Mantener | |
| `providers.tf` | Terraform | ✅ Mantener | |
| `terraform.tfvars.example` | Ejemplo | ✅ Mantener | |
| `variables.tf` | Terraform | ✅ Mantener | |
| `modules/` | Módulos | ✅ Mantener | |

#### Módulos de Terraform

| Módulo | Estado | Acción |
|:---|:---|:---|
| `active-directory/` | ✅ Completo | Añadir README por módulo |
| `arc/` | ✅ Completo | Añadir README por módulo |
| `backup/` | ✅ Completo | Añadir README por módulo |
| `corporate-storage/` | ✅ Completo | Añadir README por módulo |
| `networking/` | ✅ Completo | Añadir README por módulo |
| `security/` | ✅ Completo | Añadir README por módulo |
| `woocommerce/` | ✅ Completo | Añadir README por módulo |

**Decisión:** Mantener estructura modular. Añadir README por módulo en Fase 5.

### `terraform-lean/`

| Fichero | Tipo | Estado | Acción |
|:---|:---|:---|:---|
| `main.tf` | Terraform | ✅ Mantener | |
| `outputs.tf` | Terraform | ✅ Mantener | |
| `providers.tf` | Terraform | ✅ Mantener | |
| `variables.tf` | Terraform | ✅ Mantener | |

**Decisión:** Mantener como versión simplificada para demostraciones rápidas.

---

## Resumen de acciones por fase

| Fase | Acción | Ficheros afectados |
|:---|:---|:---|
| **Fase 0** | Crear `docs/`, inventario, auditoría | `docs/*`, `.gitignore` |
| **Fase 1** | Mover `planning.md`, `progress.md` | `docs/planning.md`, `docs/progress.md` |
| **Fase 2** | Reescribir README | `README.md` |
| **Fase 3** | Crear documentación modular | `docs/arquitectura.md`, `docs/decisiones/*`, `docs/seguridad.md`, `docs/validacion.md`, `docs/costes.md`, `docs/limitaciones.md`, `docs/runbook.md` |
| **Fase 4** | Añadir evidencias visuales | `docs/img/*` |
| **Fase 5** | CI, READMEs por módulo, publicación | `.github/workflows/*`, `terraform/modules/*/README.md` |

---

## Próximos pasos

1. Completar auditoría de seguridad (Fase 0).
2. Mover `planning.md` y `progress.md` a `docs/` (Fase 1).
3. Reescribir README como portada corta (Fase 2).
