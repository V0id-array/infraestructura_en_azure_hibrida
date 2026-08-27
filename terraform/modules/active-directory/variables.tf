variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "uid" {
  type = string
}

variable "subnet_id" {
  description = "Subred para los DCs"
  type        = string
}

variable "dc_count" {
  description = "Numero de domain controllers"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Size de las VMs"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "Usuario admin"
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Password admin"
  type        = string
  sensitive   = true
}

variable "ad_domain_name" {
  description = "FQDN del dominio"
  type        = string
  default     = "corp.enterprise.local"
}

variable "ad_netbios_name" {
  description = "NetBIOS del dominio"
  type        = string
  default     = "ENTERPRISE"
}

variable "log_analytics_workspace_id" {
  description = "Workspace para diagnosticos"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault para secretos"
  type        = string
}

