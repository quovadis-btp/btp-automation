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



variable "BTP_POSTGRESQL_PLAN" {
  description = "The name of the Postgresql-db Hyperscaler edition"
  type        = string
  default     = "freesbie"     
}


variable "runtime_context_organization" {
  type        = string
  description = "runtime_context_organization name (tfe provider)"
}

variable "runtime_context_workspace" {
  type        = string
  description = "runtime_context_workspace name (tfe provider)"
}


variable "runtime_context_backend" {
  type        = string
  description = "runtime_context_backend type"
}

variable "runtime_context_kubernetes_backend_config" {
  type = object({
    secret_suffix    = string
    config_path      = string
    namespace        = string
    load_config_file = bool
  })
}

variable "runtime_context_local_backend_config" {
  type = object({
    path = string
  })
}
