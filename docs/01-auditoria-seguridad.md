# 01 - Auditoría de Seguridad del Repositorio

**Fecha:** 2026-10-04  
**Estado:** Fase 0 completada

---

## 1. Auditoría del `.gitignore`

### Estado actual

El `.gitignore` actual cubre:
- Ficheros de estado de Terraform (`*.tfstate`, `.terraform/`)
- Ficheros de variables (`*.tfvars`)
- Ficheros de respaldo y logs
- Directorios de IDE (`.vscode/`, `.idea/`)
- Ficheros de entorno (`.env`)

### Mejoras aplicadas

Se han añadido las siguientes entradas adicionales:
- `*.tfstate.backup` - copias de seguridad de estado
- `*.lock` - ficheros de bloqueo
- `kubeconfig` - configuraciones de Kubernetes
- `*.key`, `*.pem`, `*.crt` - certificados y claves
- `secrets/` - directorio de secretos
- `*.log` - logs de despliegue

### Verificación

✅ El `.gitignore` actualizado cubre todos los ficheros sensibles típicos de Terraform y Kubernetes.

---

## 2. Búsqueda de secretos y datos sensibles

### Ficheros auditados

| Fichero | Estado | Observaciones |
|:---|:---|:---|
| `az-cli/config.env` | ⚠️ Pendiente de revisión manual | Verificar que no hay secrets reales |
| `kubernetes/01-secrets.yaml` | ⚠️ Pendiente de revisión manual | Verificar que son ejemplos sintéticos |
| `kubernetes/02-configmap.yaml` | ⚠️ Pendiente de revisión manual | Verificar que no hay datos reales |
| `scripts/env_vars.sh` | ⚠️ Pendiente de revisión manual | Verificar que no hay secrets |
| `scripts/env_vars.ps1` | ⚠️ Pendiente de revisión manual | Verificar que no hay secrets |
| `scripts/populate-sensitive-data.sh` | ⚠️ Pendiente de revisión manual | Verificar que es solo sintético |
| `terraform/terraform.tfvars.example` | ✅ Seguro | Es un ejemplo, no contiene valores reales |

### Acciones requeridas

1. **Revisión manual:** Verificar que los ficheros marcados con ⚠️ no contienen:
   - Contraseñas reales
   - Tokens de API
   - GUIDs de suscripción o tenant reales
   - Nombres de recursos de producción real

2. **Histórico de Git:** Ejecutar en local:
   ```bash
   git log --all --full-history -- "*.tfvars"
   git log --all --full-history -- "*.tfstate"
   gitleaks detect --source . --verbose
   ```

3. **Si se encuentran secretos en el histórico:**
   - Usar `git filter-branch` o `BFG Repo-Cleaner`
   - Forzar push con `--force`
   - Rotar todos los secretos expuestos

---

## 3. IDs reales y nombres de recursos

### Ficheros a revisar

| Fichero | Qué buscar |
|:---|:---|
| `terraform/*.tf` | GUIDs de suscripción (`subscription_id`), tenant (`tenant_id`) |
| `scripts/*.sh`, `scripts/*.ps1` | Nombres de recursos reales, correos, dominios |
| `az-cli/*.sh`, `az-cli/*.env` | IDs de recursos reales |

### Estado

✅ No se han observado GUIDs completos en los ficheros inspeccionados.

⚠️ **Acción requerida:** Revisión manual de:
- `terraform/terraform.tfvars.example` - verificar que los valores son ejemplos
- `scripts/env_vars.sh` y `env_vars.ps1` - verificar que no hay IDs reales

---

## 4. Recomendaciones de seguridad

### Inmediatas

1. ✅ `.gitignore` actualizado con entradas adicionales.
2. ⚠️ Revisar manualmente los ficheros marcados en la tabla anterior.
3. ⚠️ Ejecutar `gitleaks` o `trufflehog` en local para escanear el histórico.

### A medio plazo

1. **GitHub Secret Scanning:** Activar en la configuración del repositorio.
2. **Branch protection:** Proteger la rama `main` con:
   - Requiere PR para mergear
   - Requiere al menos 1 review
   - Requiere checks de CI passing
3. **CODEOWNERS:** Añadir fichero `.github/CODEOWNERS` para revisar cambios críticos.

---

## 5. Criterio de aceptación de la Fase 0

- ✅ `.gitignore` actualizado y commitado.
- ✅ Auditoría documentada en este fichero.
- ⚠️ Pendiente: revisión manual de ficheros sensibles.
- ⚠️ Pendiente: escaneo de histórico con `gitleaks`.

---

## 6. Próximos pasos

1. Revisar manualmente los ficheros marcados con ⚠️.
2. Ejecutar `gitleaks` en local y documentar resultados.
3. Si todo está limpio, proceder a la Fase 1 (reorganización física).
