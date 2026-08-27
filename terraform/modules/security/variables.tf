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
  description = "Sufijo para nombres unicos"
  type        = string
}

variable "log_analytics_retention_days" {
  description = "Dias de retencion en LAW"
  type        = number
  default     = 90
}

variable "sentinel_enabled" {
  description = "Activar Sentinel sobre LAW"
  type        = bool
  default     = true
}

variable "alert_email_receiver" {
  description = "Email receptor de alertas"
  type        = string
  default     = "admin@empresa.com"
}


