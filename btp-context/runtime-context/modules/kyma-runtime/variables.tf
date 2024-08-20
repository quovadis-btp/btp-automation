# we're using uppercase variable names, since in some cases (e.g Azure DevOps) the system variables are forced to be uppercase
# TF allows providing variable values as env variables of name name, case sensitive

variable "BTP_GLOBAL_ACCOUNT" {
  type        = string
  description = "Global account name"
}

variable "BTP_BOT_USER" {
  type        = string
  description = "Bot account name"
}

variable "BTP_BOT_PASSWORD" {
  type        = string
  description = "Bot account password"
}

variable "BTP_BACKEND_URL" {
  type        = string
  description = "BTP backend URL"
}

variable "BTP_SUBACCOUNT" {
  type        = string
  description = "Subaccount name"
}

variable "subaccount_id" {
  type        = string
  description = "The subaccount ID."
  default     = ""
}

variable "BTP_KYMA_DRY_RUN" {
  type        = bool
  description = "do not create kyma environment"
  default     = true
}

variable "BTP_KYMA_PLAN" {
  type        = string
  description = "Plan name"
  default     = "trial"
}

variable "BTP_KYMA_NAME" {
  type        = string
  description = "Plan name"
  default     = "quovadis-kyma"
}

variable "BTP_SA_REGION" {
  type        = string
  description = "Region name"
  default     = "eu20"
}

variable "BTP_CUSTOM_IDP" {
  type        = string
  description = "Custom IAS tenant fully qualified host name"
  default     = ""
}

variable "BTP_CUSTOM_IAS_TENANT" {
  type        = string
  description = "Custom IAS tenant"
  default     = ""
}

variable "BTP_CUSTOM_IAS_DOMAIN" {
  type        = string
  description = "Custom IAS domain"
  default     = ""
}

variable "BTP_KYMA_REGION" {
  type        = string
  description = "Kyma region"
  default     = "eu-de-1"
}

variable "BTP_PROVIDER_SUBACCOUNT_ID" {
  type        = string
  description = "Subaccount ID"
  default     = "subaccount-id"
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

variable "cluster_admins" {
  type        = list(string)
  description = "Designates kyma cluster administrators."
}

variable "argocd_username" {
  type        = string
  description = "argocd technical user name"
}

variable "argocd_password" {
  type        = string
  description = "argocd technical user password"
}

variable "argocd_clientid" {
  type        = string
  description = "argocd OIDC provider client id"
}

variable "argocd_tokenurl" {
  type        = string
  description = "argocd token URL"
}

variable "argocd_url" {
  type        = string
  description = "ArgoCDaaS backend URL"
}
