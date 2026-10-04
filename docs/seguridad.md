# Seguridad

**Fecha:** 2026-10-04

---

## Modelo de amenazas STRIDE

### Spoofing (Suplantación)

**Amenaza:** Conexión ilícita a recursos compartidos de archivos simulando ser un usuario corporativo.

**Control:** Autenticación Kerberos sobre canal SMB 3.1.1 con cifrado forzado e integración de identidad en Active Directory.

### Tampering (Manipulación)

**Amenaza:** Inyección de consultas maliciosas para alterar stock o precios en WooCommerce.

**Control:** Reglas de aplicación WAF de Front Door (mitigación de SQLi) y validación de parámetros en aplicación.

### Repudiation (Repudio)

**Amenaza:** Borrado o alteración de registros de auditoría por parte de un administrador comprometido.

**Control:** Ingestión continua en Log Analytics Workspace con retención inmutable y control de acceso RBAC estricto.

### Information Disclosure (Fuga)

**Amenaza:** Captura de tráfico de credenciales o documentos entre sedes locales y Azure.

**Control:** Cifrado obligatorio en tránsito mediante IPsec IKEv2 (VPN) y TLS 1.2+ en todos los endpoints PaaS.

### Denial of Service (DoS)

**Amenaza:** Saturación del backend de comercio mediante peticiones masivas al catálogo.

**Control:** Capa de protección distribuida nativa de Azure DDoS Protection y absorción de consultas estáticas en Redis.

### Elevation of Privilege (Escalada)

**Amenaza:** Movimiento lateral desde un pod comprometido en AKS hacia la red corporativa.

**Control:** Políticas de red Calico con directivas de aislamiento por defecto (DenyAll) y ausencia de IPs públicas en pods.

---

## Cobertura MITRE ATT&CK

### T1110.001 - Brute Force: Password Guessing

**Detección:** Regla analítica KQL en Microsoft Sentinel alertando de más de 10 eventos 4625 en 5 minutos.

**Estado:** Validado en laboratorio

### T1190 - Exploit Public-Facing Application

**Prevención:** Conjunto de reglas administradas DRS 1.1 en Azure Front Door WAF en modo de bloqueo.

**Estado:** Validado en laboratorio

### T1078 - Valid Accounts

**Detección:** Registro de eventos de inicio de sesión con cuentas privilegiadas y alertas de acceso anómalo.

**Estado:** Configurado en SIEM

### T1021.002 - Remote Services: SMB/Windows Admin Shares

**Prevención:** Restricción de tráfico SMB (puerto 445) a través de Firewall y aislamiento de la subred de almacenamiento.

**Estado:** Implementado en NSG/FW

### T1048 - Exfiltration Over Alternative Protocol

**Prevención:** Filtrado de tráfico saliente por Azure Firewall; bloqueo de protocolos no autorizados.

**Estado:** Implementado

---

## Reglas KQL de ejemplo

### Detección de fuerza bruta en AD

```kql
SecurityEvent
| where EventID == 4625
| summarize count() by Account, IpAddress, bin(TimeGenerated, 5m)
| where count_ > 10
```

### Bloqueos WAF

```kql
FrontDoorWebApplicationFirewallLog
| where action_s == "Block"
| summarize count() by ruleSetType_s, ruleGroup_s, ruleName_s, bin(TimeGenerated, 1h)
```

### Movimiento lateral SMB

```kql
SecurityEvent
| where EventID in (5140, 5145)
| where ShareName contains "\\"
| summarize count() by AccountName, IpAddress, bin(TimeGenerated, 1h)
```

---

## Gobierno de datos

### Microsoft Purview

- Escaneo de recursos compartidos de Azure Files autenticado mediante clave de cuenta de almacenamiento
- Algoritmos de validación sintáctica para DNI, IBAN y tarjetas de crédito (sumas de comprobación, no criptografía)
- Falsos positivos posibles en documentos con patrones coincidentes

---

## Referencias

- [Arquitectura](arquitectura.md)
- [Validación](validacion.md)
- [Decisiones](decisiones/)
