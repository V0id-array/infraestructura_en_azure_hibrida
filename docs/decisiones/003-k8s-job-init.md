# ADR 003: Job de Kubernetes para inicialización de WordPress

**Estado:** Aceptado
**Fecha:** 2026-10-04

## Contexto

WordPress requiere inicialización única (wp core install, instalación de plugins) antes de aceptar tráfico. La versión anterior usaba lifecycle.postStart en el contenedor del pod.

## Decisión

La inicialización se realiza mediante un Job de Kubernetes único y controlado, ejecutado una sola vez durante el despliegue inicial.

## Consecuencias

**Positivas:**
- Evita corrupción de base de datos por inicialización concurrente de múltiples réplicas
- Separación clara entre inicialización y ciclo de vida del pod web
- Credenciales administrativas no expuestas en ConfigMaps del despliegue
- Fácil de auditar y repetir en caso de recreación del entorno

**Negativas:**
- Requiere gestión adicional de un recurso Kubernetes
- Necesita coordinación manual para re-inicializaciones

## Riesgos del antipatrón postStart

- postStart se ejecuta asíncronamente en cada réplica al iniciar
- Múltiples pods compiten por inicializar la BD simultáneamente
- Contraseñas administrativas en texto claro en el manifiesto
- Fallos en postStart no impiden que el pod se marque temporalmente como disponible

## Referencias

- [Runbook](../runbook.md)
- [Validación](../validacion.md)
