
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

variable "subaccount_name" {
  description = "The name of the SAP BTP Subaccount"
  type        = string
}

variable "subdomain" {
  description = "The subdomain of the SAP BTP Subaccount"
  type        = string
}

variable "admins" {
  description = "The list of email addresses of the SAP BTP Subaccount Administrators"
  type        = list(string)
}

variable "region" {
  description = "The region of the SAP BTP Subaccount"
  type        = string
}

variable "service_name" {
  description = "The name of the SAP HANA Cloud service"
  type        = string
}

variable "plan_name" {
  description = "The name of the SAP HANA Cloud plan"
  type        = string
}

variable "instance_name" {
  description = "The name of the SAP HANA Cloud instance"
  type        = string
}

variable "hana_cloud_tools_app_name" {
  description = "The name of the SAP HANA Cloud Tools application"
  type        = string
}

variable "hana_cloud_tools_plan_name" {
  description = "The name of the SAP HANA Cloud Tools plan"
  type        = string
}

variable "memory" {
  description = "Memory size of the SAP HANA Cloud instance"
  type        = number
}

variable "vcpu" {
  description = "Number of vCPUs of the SAP HANA Cloud instance"
  type        = number
}

variable "storage" {
  description = "Storage size of the SAP HANA Cloud instance"
  type        = number
}
