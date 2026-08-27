# Despliegue Azure Free Tier

Script en Bash con Azure CLI (`az`) para aprovisionar VMs, balanceador con reglas NAT y Azure SQL bajo la capa gratuita de Azure.

## Requisitos

- Azure CLI (`az`)
- Python 3

## Despliegue

```bash
az login
chmod +x deploy-azure-free-tier.sh
./deploy-azure-free-tier.sh
```

## Acceso

- **SSH VM 1 (ARM64):**
  ```bash
  ssh -p 2222 azureuser@<IP_PUBLICA>
  ```
- **SSH VM 2 (AMD):**
  ```bash
  ssh -p 2223 azureuser@<IP_PUBLICA>
  ```

- **Password de BD:**
  ```bash
  az keyvault secret show --vault-name <KEYVAULT_NAME> --name admin-password --query value -o tsv
  ```

## Destruccion

```bash
az group delete --name rg-azure-free-tier --yes --no-wait
```

