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

variable "service_plan__sap_build_apps" {
  type        = string
  description = "The plan for SAP Build Apps subscription"
  default     = "free"
  validation {
    condition     = contains(["free", "standard", "partner"], var.service_plan__sap_build_apps)
    error_message = "Invalid value for service_plan__sap_build_apps. Only 'free', 'standard' and 'partner' are allowed."
  }
}

variable "service_plan__build_workzone" {
  type        = string
  description = "The plan for build_workzone subscription"
  default     = "free"
  validation {
    condition     = contains(["free", "standard"], var.service_plan__build_workzone)
    error_message = "Invalid value for service_plan__build_workzone. Only 'free' and 'standard' are allowed."
  }
}

variable "emergency_admins" {
  type        = list(string)
  description = "Defines the colleagues who are added to each subaccount as emergency administrators."
}

variable "launchpad_admins" {
  type        = list(string)
  description = "Designates launchpad admins."
}

variable "service_name" {
  description = "The name of the SAP HANA Cloud service"
  type        = string
  default     = "hana-cloud-trial"       
}

variable "plan_name" {
  description = "The name of the SAP HANA Cloud plan"
  type        = string
  default     = "hana"     
}

variable "BTP_POSTGRESQL_PLAN" {
  description = "The name of the Postgresql-db Hyperscaler edition"
  type        = string
  default     = "freesbie"     
}

variable "BTP_FREE_LAUNCHPAD_QUOTA" {
  description = "Any free launchapd service available for the subaccount"
  type        = bool 
}

#
# https://help.sap.com/docs/hana-cloud/sap-hana-cloud-administration-guide/access-administration-api
#
variable "HC_ADMIN_API_ACCESS" {
  description = "SAP HANA Cloud administration API service plan"
  type        = bool
}



variable "instance_name" {
  description = "The name of the SAP HANA Cloud instance"
  type        = string
  default     = "hc-trial"    
}

variable "hana_cloud_tools_app_name" {
  description = "The name of the SAP HANA Cloud Tools application"
  type        = string
  default     = "hana-cloud-tools-trial"  
}

variable "hana_cloud_tools_plan_name" {
  description = "The name of the SAP HANA Cloud Tools plan"
  type        = string
  default     = "tools"    
}

variable "admins" {
  description = "List of users to assign the SAP HANA Cloud Administrator role"
  type        = list(string)
  default     = null
}

variable "viewers" {
  description = "List of users to assign the SAP HANA Cloud Viewer role"
  type        = list(string)
  default     = null
}

variable "security_admins" {
  description = "List of users to assign the SAP HANA Cloud Security Administrator role"
  type        = list(string)
  default     = null
}

variable "memory" {
  description = "The memory size of the SAP HANA Cloud instance"
  type        = number
  default     = 16
}

variable "vcpu" {
  description = "The number of vCPUs of the SAP HANA Cloud instance"
  type        = number
  default     = 1
}

variable "storage" {
  description = "Storage size of the SAP HANA Cloud instance"
  type        = number
  default     = 80
}

variable "database_mappings" {
  description = "The database mapping for the SAP HANA Cloud instance"
  type = list(object({
    organization_guid = string
    space_guid        = string
  }))
  default = null
}

variable "labels" {
  description = "The labels of the SAP HANA Cloud instance"
  type        = map(string)
  default     = {}
}

variable "whitelist_ips" {
  description = "The list of IP addresses to whitelist"
  type        = list(string)
  default     = []
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
