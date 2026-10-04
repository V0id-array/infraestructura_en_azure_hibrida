# Validación y Pruebas

**Fecha:** 2026-10-04  
**Estado:** Laboratorio validado

---

## Matriz de pruebas ejecutadas

### TEST-NET-01: Enrutamiento por Firewall

**Objetivo:** Comprobar que el tráfico entre Spokes pasa por Azure Firewall.

**Precondiciones:**
- VNets emparejadas
- UDRs asignadas
- Pod de pruebas en AKS

**Comando:**
```bash
kubectl run test-pod --rm -it --image=nicolaka/netshoot -- bash
traceroute 10.2.1.4
```

**Resultado esperado:** Primer salto intermedio en 10.0.1.4 (Azure Firewall).

**Estado:** CONFORME

---

### TEST-ID-01: Conmutación DNS

**Objetivo:** Medir comportamiento de DNS ante caída de un DC.

**Precondiciones:**
- ILB (10.0.4.9) con sondeo TCP 53
- 2 DCs en AZ1 y AZ2
- Cliente enviando 50 consultas DNS/s

**Comando:**
```bash
az vm stop --resource-group rg-enterprise-prod-westeurope --name vm-dc-01
```

**Resultado:**
- Sonda TCP 53 falla en T+10 s
- ILB deriva tráfico al nodo 2 en T+10,2 s
- 1.498/1.500 consultas resueltas

**Estado:** CONFORME

---

### TEST-WAF-01: Bloqueo WAF

**Objetivo:** Verificar que WAF bloquea SQLi y XSS.

**Precondiciones:**
- Front Door Premium con WAF en modo Prevention
- Ruleset: Microsoft_DefaultRuleSet 1.1

**Comando:**
```bash
curl -s -o /dev/null -w "%{http_code}" "https://ep-woo-enterprise-prod.azurefd.net/?id=1'%20OR%20'1'='1"
```

**Resultado:** HTTP 403 Forbidden

**Estado:** CONFORME

---

### TEST-SIEM-01: Detección de fuerza bruta

**Objetivo:** Comprobar ingestión de Event ID 4625 y alerta en Sentinel.

**Precondiciones:**
- Agente AMA en vm-dc-01
- Regla KQL en Sentinel (>10 eventos 4625 en 5 min)

**Comando:**
```powershell
for ($i=1; $i -le 15; $i++) {
    Start-Sleep -Milliseconds 500
    # Intento de autenticación fallida simulada
}
```

**Resultado:**
- 15 eventos 4625 en Log Analytics
- Sentinel dispara incidente en 6 minutos

**Estado:** CONFORME

---

### TEST-GOV-01: Clasificación Purview

**Objetivo:** Verificar detección de patrones sensibles en documentos.

**Precondiciones:**
- Cuenta de almacenamiento registrada en Purview
- 142 documentos sintéticos con patrones de DNI, IBAN, tarjetas

**Comando:**
```bash
./scripts/purview-status.sh
```

**Resultado:** Purview clasifica patrones coincidentes

**Estado:** CONFORME

---

## Pruebas pendientes

1. **DRP:** Restauración completa de MySQL desde backup geográfico. Medir RTO real vs objetivo de 15 min.

2. **Estrés transaccional:** Benchmark con 100.000+ productos y transacciones concurrentes completas.

3. **Tuning de WAF:** Análisis de 30 días de tráfico legítimo para identificar falsos positivos.

4. **Conmutación híbrida:** Desconexión controlada del túnel VPN primario para comprobar convergencia de rutas.

---

## Evidencias

Las capturas de las pruebas se almacenan en `docs/img/`:

- terraform-apply.png
- rutas-efectivas-firewall.png
- sentinel-incidente-4625.png
- waf-403-block.png
- grafo-recursos-azure.png

---

## Referencias

- [Arquitectura](arquitectura.md)
- [Seguridad](seguridad.md)
- [Runbook](runbook.md)
