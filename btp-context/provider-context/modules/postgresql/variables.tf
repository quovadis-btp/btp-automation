# Define the input variables
variable "globalaccount" {
  description = "The name of the SAP BTP Global Account"
  type        = string
}

variable "username" {
  description = "The username of the SAP BTP Global Account Administrator"
  type        = string
}

variable "password" {
  description = "The password of the SAP BTP Global Account Administrator"
  type        = string
}

variable "idp" {
  type        = string
  description = "btp provider idp"
  default     = ""
}

variable "subaccount_name" {
  description = "The name of the SAP BTP Subaccount"
  type        = string
}

variable "subdomain" {
  description = "The subdomain of the SAP BTP Subaccount"
  type        = string
}

variable "region" {
  description = "The region of the SAP BTP Subaccount"
  type        = string
}

variable "subaccount_id" {
  description = "The ID of the subaccount"
  type        = string
}
