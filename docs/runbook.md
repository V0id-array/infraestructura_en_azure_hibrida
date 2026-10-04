# Runbook de Despliegue

**Fecha:** 2026-10-04  
**Tiempo estimado:** 60-90 minutos

---

## Requisitos previos

- Azure CLI instalado (versión 2.50+)
- Terraform 1.5+
- kubectl instalado
- Suscripción de Azure con permisos de contribuidor
- Presupuesto aprobado: 2.400-2.700 €/mes

---

## Paso 1: Autenticación en Azure

```bash
az login
az account set --subscription <subscription-id>
```

---

## Paso 2: Inicializar backend de Terraform

```bash
cd terraform/

# Crear storage account para el estado (si no existe)
az storage account create \
  --name tfstate<unique> \
  --resource-group rg-terraform-state \
  --location westeurope \
  --sku Standard_LRS

# Crear contenedor
az storage container create \
  --name tfstate \
  --account-name tfstate<unique>
```

---

## Paso 3: Configurar variables

```bash
cp terraform.tfvars.example terraform.tfvars

# Editar terraform.tfvars con:
# - environment: "lab"
# - location: "westeurope"
# - subscription_id: "<tu-subscription>"
# - resource_group: "rg-enterprise-lab-westeurope"
```

---

## Paso 4: Inicializar Terraform

```bash
terraform init
```

---

## Paso 5: Planificar

```bash
terraform plan -out=tfplan

# Revisar el plan:
# - Número de recursos a crear
# - Coste mensual estimado en el output
```

---

## Paso 6: Aplicar

```bash
terraform apply tfplan

# Tiempo estimado: 45-60 minutos
# Se crearán ~80-100 recursos
```

---

## Paso 7: Configurar Kubernetes

```bash
# Obtener kubeconfig
az aks get-credentials \
  --resource-group rg-enterprise-lab-westeurope \
  --name aks-woocommerce

# Verificar nodos
kubectl get nodes

# Aplicar manifiestos
cd ../kubernetes/
kubectl apply -f 01-secrets.yaml
kubectl apply -f 02-configmap.yaml
kubectl apply -f 03-pvc.yaml
kubectl apply -f 04-wordpress.yaml
```

---

## Paso 8: Validar despliegue

### Red

```bash
# Verificar rutas efectivas
az network nic show-effective-route-table \
  --ids <nic-id-del-nodo-aks>

# Debe mostrar next hop: 10.0.1.4 para 10.2.0.0/16
```

### DNS

```bash
# Consultar DNS desde dentro de la VNet
nslookup corp.enterprise.local 10.0.4.9
```

### WAF

```bash
# Probar SQLi
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  "https://<tu-frontdoor>.azurefd.net/?id=1'%20OR%20'1'='1")

echo $STATUS  # Debe ser 403
```

### Sentinel

```bash
# En portal de Azure:
# 1. Ir a Microsoft Sentinel
# 2. Verificar que hay eventos en Logs
# 3. Buscar Event ID 4625
```

---

## Paso 9: Destrucción (opcional)

```bash
cd ../terraform/
terraform destroy -auto-approve

# Tiempo estimado: 30-45 minutos
# Verificar en portal que no queden recursos
```

---

## Solución de problemas

### Error: "Subscription not registered for Microsoft.Kubernetes"

```bash
az provider register --namespace Microsoft.Kubernetes
```

### Error: "Insufficient quota"

Solicitar incremento de cuota en Azure Portal o reducir el tamaño de las VMs en `terraform.tfvars`.

### Error: "Backend already locked"

Alguien más está ejecutando Terraform. Esperar o forzar desbloqueo:

```bash
az storage blob lease break \
  --container-name tfstate \
  --blob-name terraform.tfstate \
  --account-name tfstate<unique>
```

---

## Referencias

- [Arquitectura](arquitectura.md)
- [Validación](validacion.md)
- [Costes](costes.md)
