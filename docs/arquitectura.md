# Arquitectura Técnica

**Fecha:** 2026-10-04  
**Región:** Azure West Europe

---

## Visión general

Topología Hub-and-Spoke con tres redes virtuales:

- **VNet Hub (10.0.0.0/16):** Concentra seguridad y conectividad híbrida
- **VNet Spoke WooCommerce (10.1.0.0/16):** Capa de aplicación web
- **VNet Spoke Corporate (10.2.0.0/16):** Almacenamiento y seguridad
- **Red Local Simulada (172.16.1.0/24):** Sede de Alcobendas

---

## Plan de direccionamiento

| VNet | Subred | CIDR | Función |
|:---|:---|:---|:---|
| Hub | AzureFirewallSubnet | 10.0.1.0/26 | Azure Firewall Standard (10.0.1.4) |
| Hub | GatewaySubnet | 10.0.2.0/27 | VPN Gateway VpnGw1AZ |
| Hub | AzureBastionSubnet | 10.0.3.0/26 | Azure Bastion Standard |
| Hub | snet-management | 10.0.4.0/24 | DCs (10.0.4.10, 10.0.4.11) e ILB DNS (10.0.4.9) |
| Spoke WooCommerce | snet-aks-nodes | 10.1.1.0/24 | Nodos AKS |
| Spoke WooCommerce | snet-database | 10.1.10.0/24 | MySQL Flexible Server (delegada) |
| Spoke WooCommerce | snet-cache | 10.1.11.0/24 | Private Endpoint Redis |
| Spoke Corporate | snet-storage | 10.2.1.0/24 | Private Endpoint Azure Files |
| Spoke Corporate | snet-security | 10.2.3.0/24 | Key Vault, Log Analytics |

---

## Enrutamiento

### Peering

- Hub ↔ Spoke WooCommerce: Bidireccional
- Hub ↔ Spoke Corporate: Bidireccional
- Spoke ↔ Spoke: No hay peering directo. El tráfico pasa por el Hub.

### Tablas de rutas (UDR)

Cada Spoke tiene una UDR que fuerza:

- Tráfico a otros Spokes → Next hop: Azure Firewall (10.0.1.4)
- Tráfico a red local (172.16.1.0/24) → Next hop: Azure Firewall
- Tráfico a Internet → Next hop: Azure Firewall

**Nota técnica:** Las rutas del sistema para VNet Peering tienen prefijos más específicos que 0.0.0.0/0. Por eso se necesitan rutas explícitas para cada prefijo remoto (ej. 10.2.0.0/16 desde WooCommerce) para forzar la inspección.

---

## Componentes por capa

### Conectividad híbrida

- VPN Gateway VpnGw1AZ con túnel IPsec IKEv2 a sede local
- Parámetros Fase 1: AES-256, SHA-256, DH-14, 28800s
- Parámetros Fase 2: AES-256-CBC + SHA-256, PFS-2048, 3600s
- SPOF: Enlace único sobre Internet público

### Seguridad perimetral

- Azure Firewall Standard (10.0.1.4)
- Reglas de red (L3/L4) y reglas de aplicación (FQDN L7)
- No incluye TLS deep inspection ni IDPS (requiere Premium)
- FQDNs permitidos para AKS:
  - *.hcp.westeurope.azmk8s.io
  - mcr.microsoft.com, *.cdn.mscr.io
  - management.azure.com, login.microsoftonline.com
  - ntp.ubuntu.com (UDP 123)

### Identidad

- 2x VM Windows Server 2022 Datacenter
- vm-dc-01 (10.0.4.10) en AZ1
- vm-dc-02 (10.0.4.11) en AZ2
- Dominio: corp.enterprise.local
- ILB Standard (10.0.4.9) exclusivo para DNS (TCP/UDP 53)
- Discos NTDS en Premium SSD con caching=none

### Almacenamiento corporativo

- Storage Account GRS con Azure Files
- Private Endpoint en 10.2.1.4
- Azure File Sync con servidor local
- SMB 3.1.1 con cifrado AES-256-GCM
- Autenticación Kerberos integrada en AD DS

### Cómputo web

- AKS con Azure CNI y políticas Calico
- Node pool: 1-5 nodos Standard_D2s_v3
- WordPress + WooCommerce como aplicación monolítica contenerizada
- Azure Files CSI con acceso RWX para wp-content
- HPA configurado entre 2 y 6 réplicas

### Base de datos

- Azure Database for MySQL Flexible Server 8.0
- Subred delegada 10.1.10.0/24
- HA en zona única
- Private DNS: privatelink.mysql.db.azure.com

### Caché

- Azure Cache for Redis Standard C1
- Private Endpoint en 10.1.11.4
- Private DNS: privatelink.redis.cache.windows.net
- Plugin Redis Object Cache en WordPress
- Aviso: Migración futura a Azure Managed Redis

### Borde

- Azure Front Door Premium
- Anycast edge con WAF en modo Prevention
- Ruleset: Microsoft_DefaultRuleSet 1.1
- Validación de cabecera X-Azure-FDID en backend

### Observabilidad

- Log Analytics Workspace centralizado
- Microsoft Sentinel como SIEM
- Azure Arc para servidores (DCs y storage local)
- DCR para recolección de eventos de seguridad (ej. Event ID 4625)

---

## Flujo de tráfico

### Tráfico web entrante

1. Cliente → Front Door Premium (borde de Azure)
2. Front Door → WAF (filtrado L7)
3. Front Door → AKS (snet-aks-nodes) con validación de X-Azure-FDID
4. WordPress → MySQL (snet-database) vía Private Link
5. WordPress → Redis (snet-cache) vía Private Endpoint

### Tráfico interno entre Spokes

1. Spoke WooCommerce → UDR → Next hop: Firewall (10.0.1.4)
2. Firewall aplica reglas de red y aplicación
3. Firewall → Spoke Corporate (ej. Azure Files)

### Tráfico saliente a Internet

1. Cualquier Spoke → UDR → Next hop: Firewall
2. Firewall → Internet (con filtrado FQDN para HTTP/HTTPS)

### Gestión administrativa

1. Portal Azure → Azure Bastion (10.0.3.0/26)
2. Bastion → DCs y otras VMs vía RDP/SSH
3. Sin IPs públicas en ninguna VM

---

## Referencias

- [Decisiones técnicas](decisiones/)
- [Seguridad](seguridad.md)
- [Runbook](runbook.md)
