# ADR 005: Azure Firewall Standard en laboratorio

**Estado:** Aceptado
**Fecha:** 2026-10-04

## Contexto

El cortafuegos centralizado requiere filtrado L3/L4 y L7 para tráfico saliente e inter-VNet. Azure Firewall ofrece dos SKUs: Standard y Premium.

## Decisión

Se utiliza Azure Firewall Standard en laboratorio. Premium se recomienda para producción.

## Consecuencias

**Positivas:**
- Coste reducido: Standard aprox 895 euros/mes vs Premium aprox 1.400 euros/mes
- Filtrado de red L3/L4 stateful completo
- Reglas de aplicación basadas en FQDN para HTTP/HTTPS
- Suficiente para validación de enrutamiento y controles básicos

**Negativas:**
- Sin inspección profunda de TLS (TLS termination)
- Sin prevención de intrusiones basada en firmas (IDPS)
- Sin filtrado por URL completa (solo FQDN)
- Detección de amenazas y categorías de URL limitadas

## Diferencia de coste

Premium añade aproximadamente 505 euros/mes adicionales. No justificado en laboratorio, pero recomendado para producción con tráfico sensible.

## Referencias

- [Arquitectura](../arquitectura.md)
- [Costes](../costes.md)
- [Limitaciones](../limitaciones.md)
