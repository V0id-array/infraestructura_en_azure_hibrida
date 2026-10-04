# 02 - Estructura Objetivo del Repositorio

**Fecha:** 2026-10-04  
**Estado:** Fase 0 completada

---

## Estructura final propuesta

```
infraestructura_en_azure_hibrida/
├── README.md                     # Portada corta (150-200 líneas)
├── .gitignore                    # Actualizado en Fase 0
├── architecture_diagram.drawio   # Diagrama original
├── docs/
│   ├── 00-inventario.md          # Este fichero
│   ├── 01-auditoria-seguridad.md # Auditoría de seguridad
│   ├── 02-estructura-objetivo.md # Estructura final
│   ├── arquitectura.md           # Diseño y direccionamiento (Fase 3)
│   ├── decisiones/               # ADRs (Fase 3)
│   │   ├── 001-ilb-dns-only.md
│   │   ├── 002-azure-files-rwx-lab-vs-blob-prod.md
│   │   ├── 003-k8s-job-vs-poststart.md
│   │   ├── 004-secrets-store-csi.md
│   │   ├── 005-firewall-standard-vs-premium.md
│   │   ├── 006-redis-private-endpoint.md
│   │   └── 007-managed-redis-migration.md
│   ├── seguridad.md              # STRIDE, MITRE, Sentinel (Fase 3)
│   ├── validacion.md             # Tests y evidencias (Fase 3)
│   ├── costes.md                 # Estimación y optimización (Fase 3)
│   ├── limitaciones.md           # SPOFs, SLA, pendientes (Fase 3)
│   ├── runbook.md                # Despliegue y pruebas (Fase 3)
│   ├── planning.md               # Movido desde raíz (Fase 1)
│   ├── progress.md               # Movido desde raíz (Fase 1)
│   ├── img/                      # Capturas y diagramas (Fase 4)
│   └── tree.txt                  # tree -L 3 del repo
├── queries/                      # Reglas KQL de Sentinel (Fase 3)
│   └── .gitkeep
├── terraform/
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfvars.example
│   ├── variables.tf
│   └── modules/
│       ├── active-directory/
│       │   ├── main.tf
│       │   ├── outputs.tf
│       │   ├── variables.tf
│       │   └── README.md         # Fase 5
│       ├── arc/
│       ├── backup/
│       ├── corporate-storage/
│       ├── networking/
│       ├── security/
│       └── woocommerce/
├── terraform-lean/
├── kubernetes/
├── az-cli/
├── scripts/
└── .github/
    └── workflows/
        └── terraform.yml         # CI para fmt/validate (Fase 5)
```

---

## Cambios respecto a la estructura actual

### Añadidos

- `docs/` - Documentación modular
- `docs/decisiones/` - ADRs
- `docs/img/` - Evidencias visuales
- `queries/` - Reglas KQL
- `.github/workflows/` - CI de Terraform
- READMEs por módulo en `terraform/modules/*/`

### Movimientos

- `planning.md` → `docs/planning.md`
- `progress.md` → `docs/progress.md`

### Reescrituras

- `README.md` - Convertir en portada corta
- Documentación detallada en `docs/*`

---

## Principios de diseño

1. **README como portada:** Máximo 200 líneas. El detalle va a `docs/`.
2. **Documentación modular:** Cada tema en un fichero independiente.
3. **ADRs para decisiones:** Una decisión técnica por fichero.
4. **Evidencias visibles:** Capturas en `docs/img/` referenciadas desde `validacion.md`.
5. **Reproducible:** Runbook claro en `docs/runbook.md`.
6. **Seguridad:** Nada de secrets, IDs reales o ficheros sensibles en el repo.

---

## Próximos pasos

1. **Fase 1:** Mover `planning.md` y `progress.md` a `docs/`.
2. **Fase 2:** Reescribir `README.md` como portada corta.
3. **Fase 3:** Crear documentación modular en `docs/`.
4. **Fase 4:** Añadir evidencias visuales en `docs/img/`.
5. **Fase 5:** CI, READMEs por módulo y publicación.
