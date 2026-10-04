# Documentación del Proyecto

Este directorio contiene la documentación técnica completa de la infraestructura híbrida en Azure.

## Estructura

### Documentación principal

- [Arquitectura](arquitectura.md) - Diseño técnico, direccionamiento y flujo de tráfico
- [Seguridad](seguridad.md) - Modelo STRIDE, MITRE ATT&CK y reglas KQL
- [Validación](validacion.md) - Matriz de pruebas ejecutadas y resultados
- [Limitaciones](limitaciones.md) - SPOFs, SLA y brecha laboratorio/producción
- [Costes](costes.md) - Estimación mensual y palancas de optimización
- [Runbook](runbook.md) - Pasos de despliegue y validación

### Decisiones técnicas

- [001: ILB exclusivo para DNS](decisiones/001-ilb-dns-only.md)
- [002: Azure Files CSI RWX](decisiones/002-azure-files-rwx.md)
- [003: Job de inicialización](decisiones/003-k8s-job-init.md)
- [004: Secrets Store CSI](decisiones/004-secrets-store-csi.md)
- [005: Firewall Standard](decisiones/005-firewall-standard.md)
- [006: Private Endpoint Redis](decisiones/006-redis-private-endpoint.md)
- [007: Migración a Managed Redis](decisiones/007-managed-redis-migration.md)

### Auditoría y planificación

- [00: Inventario del repositorio](00-inventario.md)
- [01: Auditoría de seguridad](01-auditoria-seguridad.md)
- [02: Estructura objetivo](02-estructura-objetivo.md)

## Uso recomendado

1. Comenzar por el [README principal](../README.md) para visión general
2. Consultar [arquitectura.md](arquitectura.md) para detalles de diseño
3. Revisar [decisiones/](decisiones/) para entender el porqué de cada elección
4. Usar [runbook.md](runbook.md) para despliegue paso a paso

## Estado de la documentación

- Fase 0: Completada (auditoría y estructura)
- Fase 1: Completada (reorganización)
- Fase 2: Completada (README principal)
- Fase 3: Completada (documentación modular)
- Fase 4: Pendiente (evidencias visuales en img/)
- Fase 5: Pendiente (CI y READMEs por módulo)
