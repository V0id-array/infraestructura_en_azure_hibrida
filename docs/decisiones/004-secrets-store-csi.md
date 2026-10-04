# ADR 004: Secrets Store CSI Driver con Workload Identity

**Estado:** Aceptado
**Fecha:** 2026-10-04

## Contexto

WordPress y MySQL requieren credenciales de base de datos, claves de administrador y otros secretos. Se prohíbe incluir contraseñas en código Base64 en el repositorio.

## Decisión

Se implementa Azure Key Vault Provider for Secrets Store CSI Driver con Azure AD Workload Identity. Los secretos se montan como volumen tmpfs en memoria dentro del pod.

## Consecuencias

**Positivas:**
- Secretos fuera del repositorio y del manifiesto
- Rotación centralizada en Key Vault
- Acceso mediante identidad federada OIDC (sin client secrets)
- Volumen inaccesible fuera del contenedor

**Negativas:**
- Complejidad adicional en configuración de federación de identidad
- Dependencia de Key Vault disponible para cada reinicio de pod
- Requiere permisos RBAC precisos en Key Vault

## Configuración

1. ServiceAccount de Kubernetes vinculada a Managed Identity de Azure mediante federación OIDC
2. Pod se asocia a la ServiceAccount
3. SecretProviderClass define qué secretos montar desde Key Vault
4. Driver CSI monta secretos en /mnt/secrets-store como tmpfs

## Referencias

- [Arquitectura](../arquitectura.md)
- [Seguridad](../seguridad.md)
