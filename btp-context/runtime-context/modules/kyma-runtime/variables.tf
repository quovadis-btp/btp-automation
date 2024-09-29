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
  description = "BTP CLI backend URL - defaults to live BTP landscapes"
  default     = "https://cli.btp.cloud.sap"
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

variable "BTP_SA_REGION" {
  type        = string
  description = "Region name"
}

variable "BTP_CUSTOM_IDP" {
  type        = string
  description = "Custom IAS tenant fully qualified host name"
  default     = ""
}

variable "BTP_KYMA_DRY_RUN" {
  type        = bool
  description = "do not create kyma environment"
  default     = true
}

variable "BTP_POSTGRESQL_DRY_RUN" {
  type        = bool
  description = "do not create postgresql-db service instance on trial"
  default     = true
}

variable "BTP_DYNATRACE_DRY_RUN" {
  type        = bool
  description = "do not bootstrap kyma cluster with dynatrace/dynakube"
  default     = true
}

variable "BTP_KYMA_PLAN" {
  type        = string
  description = "Plan name"
}

variable "BTP_KYMA_NAME" {
  type        = string
  description = "Plan name"
}

variable "BTP_KYMA_REGION" {
  type        = string
  description = "Kyma region"
}

variable "BTP_KYMA_MACHINE_TYPE" {
  type        = string
  description = "Kyma service plan machine type"
  default     = ""  
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

variable "provider_context_organization" {
  type        = string
  description = "provider_context_organization name (tfe provider)"
}

variable "provider_context_workspace" {
  type        = string
  description = "provider_context_workspace name (tfe provider)"
}


variable "provider_context_backend" {
  type        = string
  description = "provider_context_backend type"
}

variable "provider_context_kubernetes_backend_config" {
  type = object({
    secret_suffix    = string
    config_path      = string
    namespace        = string
    load_config_file = bool
  })
}

variable "provider_context_local_backend_config" {
  type = object({
    path = string
  })
}

variable "apiToken" {
  type        = string
  description = "dynatrace apiToken"
}

variable "dataIngestToken" {
  type        = string
  description = "dynatrace dataIngestToken"
}

variable "apiUrl" {
  type        = string
  description = "dynatrace apiUrl"
}

