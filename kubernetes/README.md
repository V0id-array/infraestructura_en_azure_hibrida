# Despliegue de WooCommerce en AKS

Manifiestos para levantar WordPress + WooCommerce en el clúster AKS conectado a MySQL Flexible Server.

## Despliegue

```bash
# Credenciales del clúster
az aks get-credentials --resource-group rg-enterprise-prod-westeurope --name aks-woo-enterprise-prod

# Aplicar manifiestos
kubectl apply -f 01-secrets.yaml
kubectl apply -f 02-configmap.yaml
kubectl apply -f 03-pvc.yaml
kubectl apply -f 04-wordpress.yaml
```

Verificar estado:
```bash
kubectl get pods
kubectl get svc wordpress
```

La IP pública del LoadBalancer aparecerá en `EXTERNAL-IP` de `kubectl get svc wordpress`.
El ConfigMap ejecuta WP-CLI en background para instalar WooCommerce, tema Storefront y 3 productos de prueba.

- Acceso admin: `/wp-admin`
- Usuario: `admin`
- Password: `WooAdminPassword2026!`

