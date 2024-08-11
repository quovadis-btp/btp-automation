variable "subaccount_id" {
  description = "The ID of the subaccount."
  type        = string
}

variable "plan" {
  description = "The kyma service plan to be used."
  type        = string
  default     = null
}

variable "name" {
  description = "The name of the kyma cluster."
  type        = string
}

variable "administrators" {
  description = "Users to be assigned as administrators."
  type        = set(string)
  default     = []
}

variable "oidc" {
  description = "Custom OpenID Connect IdP to authenticate users in your Kyma runtime."
  type = object({
    # the URL of the OpenID issuer (use the https schema)
    issuer_url = string

    # the client ID for the OpenID client
    client_id = string

    #the name of a custom OpenID Connect claim for specifying user groups
    groups_claim = string

    # the list of allowed cryptographic algorithms used for token signing. The allowed values are defined by RFC 7518.
    signing_algs = set(string)

    # the prefix for all usernames. If you don't provide it, username claims other than “email” are prefixed by the issuerURL to avoid clashes. To skip any prefixing, provide the value as -.
    username_prefix = string

    # the name of a custom OpenID Connect claim for specifying a username
    username_claim = string
  })
  default = null
}

variable "region" {
  description = "The region of the kyma environment"
  type        = string
  default     = "us10"
}


variable "kyma_config_template" {
  type = object({
    name            = string
    region          = string
#    machine_type    = string
#    auto_scaler_min = number
#    auto_scaler_max = number
    administrators = set(string)
  })
  description = "Your Kyma environment configuration parameters. Name and region are mandatory. Please refer to the following documentation for more details: https://help.sap.com/docs/btp/sap-business-technology-platform/provisioning-and-update-parameters-in-kyma-environment."
  default     = null

  #validation {
  #  condition = (
  #    var.kyma_config_template == null ? true : length(var.kyma_config_template.name) > 0 && length(var.kyma_config_template.region) > 0
  #  )
  #  error_message = "Value for kyma_config_template must either be null or an object with values for at least name and region"
  #}
}