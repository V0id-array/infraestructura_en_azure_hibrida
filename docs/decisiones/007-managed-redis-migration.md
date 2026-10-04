# ADR 007: Migración futura a Azure Managed Redis

**Estado:** Propuesto
**Fecha:** 2026-10-04

## Contexto

Microsoft ha anunciado el cese de evolución e inicio del plan de retirada de Azure Cache for Redis tradicional en favor de Azure Managed Redis (oferta unificada basada en Redis Enterprise).

## Decisión

Planificar migración a Azure Managed Redis antes de la fecha límite de soporte de la oferta tradicional.

## Consecuencias

**Positivas:**
- Soporte a largo plazo garantizado
- Configuraciones de escalado elástico mejoradas
- Alta disponibilidad multizona nativa
- Persistencia de datos opcional

**Negativas:**
- Coste potencialmente mayor
- Requiere planificación y testing de migración
- Posible downtime controlado durante migración

## Timeline recomendado

1. Q4 2026: Evaluar Azure Managed Redis en entorno de pruebas
2. Q1 2027: Diseñar arquitectura de migración (activo-pasivo o blue-green)
3. Q2 2027: Ejecutar migración en ventana de mantenimiento

## Referencias

- [Limitaciones](../limitaciones.md)
- [Costes](../costes.md)
