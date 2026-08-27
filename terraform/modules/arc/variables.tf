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

variable "log_analytics_workspace_id" {
  description = "Workspace para logs de Arc"
  type        = string
}

variable "log_analytics_workspace_key" {
  description = "Primary key del workspace"
  type        = string
  sensitive   = true
}

