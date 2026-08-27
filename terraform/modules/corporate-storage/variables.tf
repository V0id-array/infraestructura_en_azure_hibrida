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

variable "purview_managed_rg_name" {
  description = "RG administrado de Purview"
  type        = string
}

variable "corporate_subnet_storage_id" {
  description = "Subred para private endpoint"
  type        = string
}

variable "corporate_vnet_id" {
  description = "VNet para el DNS link"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Workspace de logs"
  type        = string
}

variable "file_share_quota_gb" {
  description = "Cuota en GB del file share"
  type        = number
  default     = 100
}

