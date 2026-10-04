# Limitaciones y Brechas

**Fecha:** 2026-10-04

---

## Disponibilidad (RNF-01)

### Cálculo en serie

Componentes críticos en el camino de petición:

1. Front Door Premium: 99,99%
2. AKS (plano de control): 99,95%
3. Nodos AKS (multizona): 99,99%
4. MySQL Flexible Server (HA en zona): 99,95%
5. Redis Standard: 99,99%
6. Azure Firewall Standard: 99,99%

**Disponibilidad compuesta:**

0,9999 × 0,9995 × 0,9999 × 0,9995 × 0,9999 × 0,9999 = 0,99870 = 99,870%

**Objetivo:** 99,95%

**Brecha:** 0,080% (aproximadamente 35 minutos adicionales de indisponibilidad al mes)

### Implicaciones

- No se puede certificar contractualmente el cumplimiento del 99,95%
- Requiere arquitectura multirregional activo-pasivo o activo-activo
- Necesita desacoplamiento asíncrono de componentes críticos

---

## SPOFs residuales

### Enlace VPN híbrido

**Riesgo:** Alto

**Fallo no cubierto:** Caída del ISP local o avería del router on-premises

**Mitigación recomendada:**
- Segundo enlace de fibra con operador independiente
- Router redundante bajo VRRP/BGP
- Azure ExpressRoute con VPN de respaldo

### Agente Azure File Sync

**Riesgo:** Medio

**Fallo no cubierto:** Avería del servidor local de archivos

**Mitigación recomendada:**
- Azure File Sync en clúster de conmutación por error de Windows Server
- Múltiples Server Endpoints

### Región de Azure

**Riesgo:** Bajo (pero impacto crítico)

**Fallo no cubierto:** Incidente mayor en West Europe

**Mitigación recomendada:**
- Réplica pasiva en North Europe
- Replicación asíncrona de datos
- Front Door con conmutación por error global

### Plano de control (Entra ID / ARM)

**Riesgo:** Medio

**Fallo no cubierto:** Caída global de autenticación o gestión

**Mitigación recomendada:**
- Procedimientos fuera de banda
- Documentación operativa local para contingencias
- Cuentas de emergencia (break-glass)

---

## Brecha laboratorio/producción

| Componente | Laboratorio | Producción recomendada |
|:---|:---|:---|
| Firewall | Standard (sin TLS inspection) | Premium (IDPS, TLS deep inspection) |
| Redis | Azure Cache for Redis Standard | Azure Managed Redis (soporte a largo plazo) |
| Almacenamiento web | Azure Files CSI RWX | Blob Storage + CDN (stateless) |
| Conectividad híbrida | VPN IPsec sobre Internet | ExpressRoute + VPN de respaldo |
| Base de datos | HA en zona única | Geo-redundante con failover automático |

---

## Pruebas no validadas

1. DRP con medición cronometrada de RTO/RPO
2. Estrés transaccional con base de datos poblada (>100.000 productos)
3. Tuning de WAF con 30 días de tráfico real
4. Conmutación por error de conectividad híbrida

---

## Referencias

- [Arquitectura](arquitectura.md)
- [Costes](costes.md)
- [Runbook](runbook.md)
