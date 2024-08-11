data "btp_regions" "all" {}

data "btp_globalaccount" "this" {}

data "btp_subaccount" "this" {
  id = var.subaccount_id
}

# ------------------------------------------------------------------------------------------------------
# Execute the Kyma instance creation
# ------------------------------------------------------------------------------------------------------
locals {
  subaccount_iaas_provider = [for region in data.btp_regions.all.values : region if region.region == data.btp_subaccount.this.region][0].iaas_provider
}


resource "btp_subaccount_entitlement" "kymaruntime" {
  subaccount_id = var.subaccount_id

  service_name = "kymaruntime"
  plan_name    = var.plan != null ? var.plan : lower(local.subaccount_iaas_provider)
  amount       = 1
}

data "btp_whoami" "me" {}


data "btp_subaccount_environments" "all" {
  subaccount_id = var.subaccount_id
  depends_on    = [btp_subaccount_entitlement.kymaruntime]
}


# Take the first kyma region from the first kyma environment if no kyma instance parameters are provided
resource "null_resource" "cache_kyma_region" {
  triggers = {
    region = var.kyma_config_template != null ? var.kyma_config_template.region : jsondecode([for env in data.btp_subaccount_environments.all.values : env if env.service_name == "kymaruntime" && env.environment_type == "kyma" && env.plan_name == lower(local.subaccount_iaas_provider)][0].schema_create).parameters.properties.region.enum[0]
  }

  lifecycle {
    ignore_changes = all
  }
} 

locals {
  kyma_instance_parameters = var.kyma_config_template != null ? var.kyma_config_template : {
    name   = var.name
    region = null_resource.cache_kyma_region.triggers.region
    administrators = toset(concat(tolist(var.administrators), [data.btp_whoami.me.email]))
  }
}  

resource "btp_subaccount_environment_instance" "kymacluster" {
  subaccount_id = var.subaccount_id

  name             = var.name
  environment_type = "kyma"
  service_name     = btp_subaccount_entitlement.kymaruntime.service_name
  plan_name        = btp_subaccount_entitlement.kymaruntime.plan_name

  parameters = jsonencode(merge({
    name           = var.name
    administrators = toset(concat(tolist(var.administrators), [data.btp_whoami.me.email]))
    }, var.oidc == null ? null : {
    issuerURL      = var.oidc.issuer_url
    clientID       = var.oidc.client_id
    groupsClaim    = var.oidc.groups_claim
    usernameClaim  = var.oidc.username_claim
    usernamePrefix = var.oidc.username_prefix
    signingAlgs    = var.oidc.signing_algs
  }))

  depends_on = [btp_subaccount_entitlement.kymaruntime]

  timeouts = {
    read   = "10m"
    create = "40m"
    update = "20m"
    delete = "20m"
  }
}

data "http" "kubeconfig" {
  url = jsondecode(btp_subaccount_environment_instance.kymacluster.labels)["KubeconfigURL"]
}

resource "local_sensitive_file" "kubeconfig" {
  filename = ".${var.subaccount_id}-${var.name}.kubeconfig"
  content  = data.http.kubeconfig.response_body
}
