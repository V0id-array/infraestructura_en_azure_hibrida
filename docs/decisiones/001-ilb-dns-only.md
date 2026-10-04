# ADR 001: Internal Load Balancer exclusivo para DNS

**Estado:** Aceptado  
**Fecha:** 2026-10-04

## Contexto

Se requiere alta disponibilidad en el servicio de resolución de nombres DNS para el dominio corp.enterprise.local. Dos controladores de dominio en zonas de disponibilidad distintas (AZ1 y AZ2) necesitan un punto de acceso único para clientes DNS.

## Decisión

El Internal Load Balancer Standard (10.0.4.9) se configura exclusivamente para tráfico DNS (puertos TCP/UDP 53). No se utiliza para LDAP, Kerberos ni otros servicios de Active Directory.

## Consecuencias

### Positivas

- Conmutación automática ante fallo de un DC en aproximadamente 10 segundos
- Simplificación de configuración de clientes DNS
- Separación clara de responsabilidades por puerto

### Negativas

- Clientes AD deben usar DCs individuales (10.0.4.10, 10.0.4.11) para autenticación
- No se puede usar el ILB como punto único para todos los servicios de directorio
- Requiere configuración manual de sitios y servicios de AD para localización de DCs

## Justificación técnica

Active Directory utiliza el mecanismo DC Locator que consulta registros DNS SRV (_ldap._tcp.dc._msdcs) y realiza ping CLDAP para seleccionar el controlador más cercano. Kerberos asocia tickets SPN al nombre del equipo destino, lo que causa fallo de autenticación si se usa una IP virtual compartida sin reconfiguración compleja de SPNs.

## Referencias

- [Arquitectura](../arquitectura.md)
- [Validación](../validacion.md#test-id-01-conmutación-dns)
