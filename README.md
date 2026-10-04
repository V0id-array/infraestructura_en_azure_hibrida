# Infraestructura Híbrida en Azure - Laboratorio

[![Terraform](https://img.shields.io/badge/Terraform-1.5-623CE4?logo=terraform)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-West%20Europe-0078D4?logo=microsoft-azure)](https://azure.microsoft.com/)
[![AKS](https://img.shields.io/badge/AKS-Kubernetes-326CE5?logo=kubernetes)](https://azure.microsoft.com/services/kubernetes-service/)
[![Sentinel](https://img.shields.io/badge/Sentinel-SIEM-0078D4?logo=microsoft)](https://azure.microsoft.com/services/azure-sentinel/)

Laboratorio de infraestructura híbrida empresarial en Azure con red Hub-and-Spoke, identidad distribuida, almacenamiento corporativo y tienda WooCommerce en AKS. Todo desplegado con Terraform y monitorizado con Microsoft Sentinel.

**Estado:** Laboratorio validado. No es una arquitectura de producción.

---

## Qué es este proyecto

Infraestructura como código (IaC) que implementa un escenario empresarial ficticio (Novatech Retail) con:

- Red híbrida Hub-and-Spoke conectada a sede local mediante VPN IPsec Site-to-Site
- Identidad con dos controladores de dominio Windows Server 2022 en zonas de disponibilidad distintas
- Almacenamiento departamental con Azure Files + Private Endpoint + Azure File Sync
- Tienda WooCommerce contenerizada en AKS con MySQL Flexible Server, Redis y Front Door Premium con WAF
- Monitorización centralizada con Log Analytics y Microsoft Sentinel para detección de incidentes

El diseño responde a retos reales de coexistencia entre recursos locales y servicios cloud: segmentación de red, resolución de nombres, control perimetral y observabilidad de seguridad.

---

## Componentes principales

| Servicio | SKU | Función |
|:---|:---|:---|
| Azure Firewall | Standard | Cortafuegos centralizado para tráfico saliente e inter-VNet |
| VPN Gateway | VpnGw1AZ | Terminación de túnel IPsec Site-to-Site |
| Azure Bastion | Standard | Acceso administrativo RDP/SSH sin IPs públicas |
| Controladores de dominio | 2x Standard_D2s_v3 | AD DS en AZ1 y AZ2 con ILB exclusivo para DNS |
| AKS | Standard | Clúster Kubernetes con Azure CNI y Calico |
| MySQL Flexible Server | General Purpose D2ds_v4 | Base de datos para WooCommerce |
| Azure Cache for Redis | Standard C1 | Caché de objetos para WordPress |
| Azure Front Door | Premium + WAF | Punto de entrada global con reglas DRS 1.1 |
| Azure Files | GRS + Private Endpoint | Almacenamiento SMB con Azure File Sync |
| Log Analytics + Sentinel | SIEM | Centralización de eventos y detección de amenazas |

---

## Resultados validados en laboratorio

- Tráfico entre redes Spoke forzado a pasar por Azure Firewall (verificado con traceroute)
- Conmutación DNS en aproximadamente 10,2 segundos ante caída de un controlador de dominio
- WAF bloqueando peticiones con patrones SQLi y XSS (HTTP 403)
- Alerta de fuerza bruta en Active Directory (Event ID 4625) disparada en Sentinel en 6 minutos
- 100% de recursos desplegados mediante Terraform sin intervención manual

---

## Decisiones técnicas clave

- **ILB solo para DNS:** El Internal Load Balancer (10.0.4.9) se restringe al puerto 53. LDAP y Kerberos van directos a los DCs por incompatibilidad con el DC Locator y SPNs.
- **Job de Kubernetes para init:** La inicialización de WordPress se hace con un Job único, no con postStart, para evitar corrupción por inicialización concurrente.
- **Firewall Standard en laboratorio:** No hay TLS deep inspection ni IDPS. Premium añade unos 505 €/mes adicionales.
- **Azure Files CSI RWX:** En laboratorio se usa para wp-content. En producción se recomienda WordPress sin estado con Blob Storage.
- **Private Endpoint para Redis:** Conectividad privada sin exposición pública. Aviso de migración futura a Azure Managed Redis.

Ver [docs/decisiones/](docs/decisiones/) para ADRs completos.

---

## Limitaciones y trabajos pendientes

- **Disponibilidad:** El cálculo en serie arroja 99,870%, por debajo del objetivo de 99,95%. Requiere arquitectura multirregional.
- **Región única:** Toda la infraestructura está en West Europe. Sin DR en región secundaria.
- **VPN única:** El enlace híbrido depende de un único túnel IPsec. Sin ExpressRoute ni enlace secundario.
- **Pruebas pendientes:** DRP con medición de RTO/RPO, estrés transaccional real, tuning de WAF, conmutación de conectividad.

Ver [docs/limitaciones.md](docs/limitaciones.md) para análisis completo.

---

## Inicio rápido

### Requisitos

- Azure CLI instalado y autenticado
- Terraform 1.5+
- Suscripción de Azure con permisos de contribuidor
- Presupuesto estimado: 2.680 €/mes (ver [docs/costes.md](docs/costes.md))

### Despliegue

```bash
cd terraform/
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Destrucción

```bash
terraform destroy -auto-approve
```

**Advertencia:** Esto elimina todos los recursos. Asegúrate de no necesitar nada antes de ejecutar.

---

## Estructura del repositorio

```
infraestructura_en_azure_hibrida/
├── README.md              # Este fichero
├── docs/                  # Documentación modular
│   ├── arquitectura.md    # Diseño y direccionamiento
│   ├── decisiones/        # ADRs
│   ├── seguridad.md       # STRIDE, MITRE, Sentinel
│   ├── validacion.md      # Tests y evidencias
│   ├── costes.md          # Estimación y optimización
│   ├── limitaciones.md    # SPOFs, SLA, pendientes
│   └── runbook.md         # Despliegue y pruebas
├── terraform/             # Infraestructura principal
│   └── modules/           # Módulos por capa
├── terraform-lean/        # Versión simplificada
├── kubernetes/            # Manifiestos de AKS
├── az-cli/                # Scripts alternativos en Azure CLI
├── scripts/               # Scripts auxiliares
└── queries/               # Reglas KQL para Sentinel
```

---

## Documentación

- [Arquitectura](docs/arquitectura.md) - Diseño de red, direccionamiento y flujo de tráfico
- [Decisiones técnicas](docs/decisiones/) - ADRs detallados
- [Seguridad](docs/seguridad.md) - STRIDE, MITRE ATT&CK, reglas KQL
- [Validación](docs/validacion.md) - Matriz de pruebas y evidencias
- [Costes](docs/costes.md) - Desglose mensual y optimización
- [Limitaciones](docs/limitaciones.md) - SPOFs y brecha laboratorio/producción
- [Runbook](docs/runbook.md) - Pasos de despliegue y validación

---

## Seguridad

Este repositorio no contiene:
- Secrets, tokens ni contraseñas reales
- GUIDs de suscripción o tenant de producción
- Ficheros de estado (`.tfstate`) ni variables con valores reales (`.tfvars`)

Ver [docs/01-auditoria-seguridad.md](docs/01-auditoria-seguridad.md) para detalles de la auditoría.

---

## Licencia y contacto

**Licencia:** MIT

**Autor:** Félix Sánchez González  
**LinkedIn:** [Perfil](https://www.linkedin.com/in/felix-sanchez)  
**Portfolio:** [Web](https://tu-portfolio.dev)

---

*Proyecto de laboratorio con fines educativos. No desplegar en producción sin revisión arquitectónica y de seguridad.*
