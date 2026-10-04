# ADR 006: Private Endpoint para Azure Cache for Redis

**Estado:** Aceptado
**Fecha:** 2026-10-04

## Contexto

Azure Cache for Redis requiere conectividad desde AKS sin exposición a Internet público. La SKU Standard C1 no soporta inyección directa en VNet.

## Decisión

Se configura un Private Endpoint en la subred snet-cache (10.1.11.4) con resolución DNS vía zona privada privatelink.redis.cache.windows.net.

## Consecuencias

**Positivas:**
- Sin exposición pública de Redis
- Tráfico por backbone de Azure (no Internet)
- Compatible con SKU Standard C1
- Aislamiento de red completo

**Negativas:**
- Configuración adicional de DNS privada
- Dependencia de resolución DNS correcta
- La SKU Standard no tiene persistencia de datos

## Configuración

1. Crear Private Endpoint en subred dedicada
2. Configurar zona DNS privada para privatelink.redis.cache.windows.net
3. WordPress usa plugin Redis Object Cache con endpoint privado
4. Excluir cookies de sesión de WooCommerce de la caché

## Referencias

- [Arquitectura](../arquitectura.md)
- [Seguridad](../seguridad.md)
