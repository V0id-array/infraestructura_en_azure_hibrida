variable "project_name" {
  description = "Prefijo para los nombres de recursos"
  type        = string
  default     = "enterprise"
}

variable "environment" {
  description = "dev, staging o prod"
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Valores permitidos: dev, staging, prod."
  }
}

variable "location" {
  description = "Region principal de Azure"
  type        = string
  default     = "westeurope"
}

variable "tags" {
  description = "Tags base del proyecto"
  type        = map(string)
  default = {
    Proyecto  = "InfraestructuraEmpresarial"
    ManagedBy = "Terraform"
  }
}

variable "hub_vnet_address_space" {
  description = "CIDR del Hub"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "woocommerce_vnet_address_space" {
  description = "CIDR spoke WooCommerce"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "corporate_vnet_address_space" {
  description = "CIDR spoke Corporate"
  type        = list(string)
  default     = ["10.2.0.0/16"]
}

variable "on_premises_sites" {
  description = "Sedes para VPN S2S"
  type = map(object({
    gateway_ip    = string
    address_space = list(string)
    shared_key    = string
    description   = string
  }))
  default = {}
}

variable "aks_node_count" {
  description = "Nodos iniciales del pool AKS"
  type        = number
  default     = 2
}

variable "aks_node_vm_size" {
  description = "Size de las VMs del nodepool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "mysql_sku_name" {
  description = "Tier/SKU de MySQL Flexible"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "mysql_admin_username" {
  description = "Usuario admin MySQL"
  type        = string
  default     = "woo_admin"
}

variable "mysql_admin_password" {
  description = "Password admin MySQL"
  type        = string
  sensitive   = true
}

variable "purview_managed_rg_name" {
  description = "RG gestionado interno de Purview"
  type        = string
  default     = "rg-purview-managed"
}

variable "arc_enabled" {
  description = "Desplegar DCRs y politicas de Arc"
  type        = bool
  default     = true
}

variable "ad_dc_count" {
  description = "Cantidad de DCs a desplegar"
  type        = number
  default     = 2
}

variable "ad_vm_size" {
  description = "Size de las VMs de Active Directory"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "ad_admin_username" {
  description = "Usuario admin local/dominio"
  type        = string
  default     = "azureadmin"
}

variable "ad_admin_password" {
  description = "Password para admin y DSRM"
  type        = string
  sensitive   = true
}

variable "ad_domain_name" {
  description = "FQDN del dominio AD"
  type        = string
  default     = "corp.enterprise.local"
}

variable "ad_netbios_name" {
  description = "NetBIOS del dominio"
  type        = string
  default     = "ENTERPRISE"
}

