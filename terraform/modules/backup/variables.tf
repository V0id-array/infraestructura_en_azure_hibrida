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

variable "vm_ids" {
  description = "VMs a incluir en la policy de backup"
  type        = list(string)
  default     = []
}

variable "vm_names" {
  description = "Nombres de las VMs"
  type        = list(string)
  default     = []
}

variable "storage_account_id" {
  description = "ID de la cuenta de storage"
  type        = string
}

variable "storage_account_name" {
  description = "Nombre de la storage account"
  type        = string
}

variable "file_share_name" {
  description = "Share a respaldar"
  type        = string
}

variable "arc_enabled" {
  description = "Configurar backup para Arc"
  type        = bool
  default     = true
}

