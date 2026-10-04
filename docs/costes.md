# Estimación de Costes

**Fecha:** 2026-10-04  
**Región:** Azure West Europe  
**Moneda:** Euros (€) - Precios públicos sin impuestos

---

## Desglose mensual estimado

### Conectividad y red

| Recurso | SKU | Coste mensual |
|:---|:---|:---|
| Azure Firewall | Standard + 500 GB procesamiento | 895,00 € |
| VPN Gateway | VpnGw1AZ | 148,00 € |
| Azure Bastion | Standard | 175,00 € |
| VNet Peering | 1.000 GB transferidos | 8,00 € |
| **Subtotal** | | **1.226,00 €** |

### Identidad (AD DS)

| Recurso | SKU | Coste mensual |
|:---|:---|:---|
| 2x Máquinas Virtuales | Standard_D2s_v3 | 142,00 € |
| Discos SO y NTDS | Premium SSD (4 discos) | 38,00 € |
| Internal Load Balancer | Standard | 16,50 € |
| **Subtotal** | | **196,50 €** |

### Cómputo web y datos

| Recurso | SKU | Coste mensual |
|:---|:---|:---|
| AKS (plano de control) | Standard | 65,00 € |
| Nodos AKS | 2x Standard_D2s_v3 | 142,00 € |
| MySQL Flexible Server | General Purpose D2ds_v4, 100 GB | 115,00 € |
| Azure Cache for Redis | Standard C1 | 95,00 € |
| Azure Front Door | Premium + WAF | 295,00 € |
| **Subtotal** | | **712,00 €** |

### Almacenamiento híbrido

| Recurso | SKU | Coste mensual |
|:---|:---|:---|
| Azure Files | GRS, 500 GB + operaciones | 85,00 € |
| Azure File Sync | 1 servidor registrado | 5,00 € |
| Private Endpoints | 5 endpoints | 32,00 € |
| **Subtotal** | | **122,00 €** |

### Seguridad y resiliencia

| Recurso | SKU | Coste mensual |
|:---|:---|:---|
| Log Analytics / Sentinel | 3 GB/día, 90 días retención | 68,00 € |
| Recovery Services Vault | 2 VMs + Files, GRS | 78,00 € |
| Azure Key Vault | Standard | 2,50 € |
| **Subtotal** | | **148,50 €** |

---

## Total mensual

**Total estimado: 2.405,00 €/mes**

**Rango de incertidumbre:** ±15% (variación por uso real de procesamiento, tráfico y operaciones)

---

## Palancas de optimización

### Azure Hybrid Benefit

Reutilización de licencias Windows Server con Software Assurance:
- Hasta 45% de ahorro en VMs de AD DS
- Hasta 45% de ahorro en nodos AKS (si aplica)

**Ahorro estimado: 100-150 €/mes**

### Instancias reservadas (3 años)

Para recursos de cómputo y base de datos con utilización continua:
- Controladores de dominio
- MySQL Flexible Server
- Nodos AKS (línea base)

**Ahorro estimado: hasta 38% en cómputo**

### Apagado programado (laboratorio)

Para entornos que no prestan servicio a usuarios finales:
- Detener VMs y reducir nodos AKS fuera de horario laboral
- Automatizar con Azure Automation o Logic Apps

**Ahorro estimado: 60% en cómputo (si se usa 8h/día, 5d/semana)**

---

## Notas

- Precios de catálogo de Azure Retail Prices API
- No incluye costes de personal, conectividad local ni migración
- Los precios pueden cambiar. Verificar en Azure Pricing Calculator

---

## Referencias

- [Arquitectura](arquitectura.md)
- [Limitaciones](limitaciones.md)
- [Runbook](runbook.md)
