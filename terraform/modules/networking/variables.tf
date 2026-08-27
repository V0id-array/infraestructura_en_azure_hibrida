variable "resource_group_name" {
  description = "RG principal"
  type        = string
}

variable "location" {
  description = "Region Azure"
  type        = string
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

variable "hub_vnet_address_space" {
  description = "CIDR del Hub"
  type        = list(string)
}

variable "woocommerce_vnet_address_space" {
  description = "CIDR del spoke WooCommerce"
  type        = list(string)
}

variable "corporate_vnet_address_space" {
  description = "CIDR del spoke Corporate"
  type        = list(string)
}

variable "on_premises_sites" {
  description = "Sedes remotas para VPN S2S"
  type = map(object({
    gateway_ip    = string
    address_space = list(string)
    shared_key    = string
    description   = string
  }))
  default = {}
}

