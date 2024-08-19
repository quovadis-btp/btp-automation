
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

variable "origin" {
  type        = string
  description = "btp provider idp origin key"
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

variable "emergency_admins" {
  type        = list(string)
  description = "Defines the colleagues who are added to each subaccount as emergency administrators."
}

variable "platform_admins" {
  type        = list(string)
  description = "Designates global account administrators as platform users."
}

variable "region" {
  description = "The region of the SAP BTP Subaccount"
  type        = string
}

variable "BTP_KYMA_PLAN" {
  type        = string
  description = "Plan name"
  default     = "trial"
}


