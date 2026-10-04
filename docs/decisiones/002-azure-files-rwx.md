# ADR 002: Azure Files CSI RWX para WordPress

**Estado:** Aceptado
**Fecha:** 2026-10-04

## Contexto

WordPress con WooCommerce requiere almacenamiento persistente compartido para wp-content (plugins, temas, uploads). En Kubernetes, múltiples réplicas del despliegue necesitan acceso simultáneo al mismo volumen.

## Decisión

En laboratorio se utiliza Azure Files CSI driver con clase de almacenamiento azurefile-csi que soporta modo de acceso ReadWriteMany (RWX).

## Consecuencias

**Positivas:**
- Múltiples pods pueden montar el mismo volumen simultáneamente
- Configuración simple mediante StorageClass existente
- Compatible con WordPress monolítico sin modificaciones

**Negativas:**
- Latencia mayor que Azure Disk para operaciones de archivo
- Cuello de botella potencial bajo alta concurrencia de escritura
- No es la arquitectura óptima para producción a escala

## Alternativa para producción

WordPress sin estado con:
- Código PHP, temas y plugins empaquetados en imagen Docker inmutable
- Medios estáticos (wp-content/uploads) en Azure Blob Storage
- Plugin de offload de medios para redirección automática
- Blob servido vía CDN para mejor rendimiento global

## Referencias

- [Arquitectura](../arquitectura.md)
- [Runbook](../runbook.md)
