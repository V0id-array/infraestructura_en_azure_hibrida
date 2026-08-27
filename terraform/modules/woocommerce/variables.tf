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

variable "aks_kubernetes_version" {
  description = "Version K8s"
  type        = string
  default     = "1.34"
}

variable "aks_node_count" {
  type    = number
  default = 2
}

variable "aks_node_vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "mysql_sku_name" {
  type    = string
  default = "B_Standard_B1ms"
}

variable "mysql_admin_username" {
  type = string
}

variable "mysql_admin_password" {
  type      = string
  sensitive = true
}

variable "aks_subnet_id" {
  type = string
}

variable "db_subnet_id" {
  type = string
}

variable "cache_subnet_id" {
  type = string
}

variable "woo_vnet_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "key_vault_id" {
  type = string
}

