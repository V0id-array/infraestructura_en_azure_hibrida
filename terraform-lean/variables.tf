variable "location" {
  type    = string
  default = "spaincentral"
}

variable "purview_location" {
  description = "Región soportada por Microsoft Purview"
  type        = string
  default     = "francecentral"
}

variable "environment" {
  type    = string
  default = "prod"
}
