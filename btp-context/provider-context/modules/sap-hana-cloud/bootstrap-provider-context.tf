

# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id
resource "random_id" "context_id" {
  byte_length = 4
  prefix      = "quovadis-"
}

locals {
  context_id        = random_id.context_id.hex
  subaccount_domain = lower("${var.subaccount_name}-${local.context_id}")
  subaccount_name   = lower("${var.subdomain}-${local.context_id}")

  region            = lower("${var.region}")
}


resource "btp_subaccount" "this" {
  count     = var.subaccount_id == "" ? 1 : 0

  name        = local.subaccount_name
  subdomain   = local.subaccount_domain
  region      = local.region
  usage       = "USED_FOR_PRODUCTION"
  description = "${local.subaccount_name} is a provider context subaccount"
  labels      = {
      "${var.subaccount_name}" = [""]
  } 
}

data "btp_subaccount" "context" {
  id = var.subaccount_id != "" ? var.subaccount_id : btp_subaccount.this[0].id
}

/*
resource "local_file" "subaccount_id" {
  content  = data.btp_subaccount.context.id
  filename = "subaccount_id.txt"
}
*/

resource "btp_subaccount_role_collection_assignment" "subaccount_users" {
  depends_on           = [data.btp_subaccount.context, btp_subaccount_trust_configuration.custom_idp]

  for_each             = toset("${var.emergency_admins}")
  subaccount_id        = data.btp_subaccount.context.id
  role_collection_name = "Subaccount Administrator"
  user_name            = each.value
  origin               = btp_subaccount_trust_configuration.custom_idp.origin
}



## bootstrap custom idp trust for the provider subaccount

resource "btp_subaccount_entitlement" "identity" {
  count         = var.idp == "" ? 1 : 0

  subaccount_id = data.btp_subaccount.context.id
  service_name  = "sap-identity-services-onboarding"
  plan_name     = "default"
}

resource "btp_subaccount_subscription" "identity_instance" {
  depends_on    = [btp_subaccount_entitlement.identity]
  count         = var.idp == "" ? 1 : 0

  subaccount_id = data.btp_subaccount.context.id
  app_name      = "sap-identity-services-onboarding"
  plan_name     = "default"
  parameters    = jsonencode({
    cloud_service = "PROD"
  })
}

data "btp_subaccount_trust_configuration" "custom_idp" {
  depends_on    = [btp_subaccount_trust_configuration.custom_idp]
  subaccount_id = data.btp_subaccount.context.id
  origin        = btp_subaccount_trust_configuration.custom_idp.origin
}


resource "btp_subaccount_trust_configuration" "custom_idp" {
  subaccount_id     = data.btp_subaccount.context.id
  identity_provider = var.idp != "" ? var.idp : element(split("/", btp_subaccount_subscription.identity_instance[0].subscription_url), 2)
  name              = "${local.subaccount_domain}"

  depends_on        = [btp_subaccount_subscription.identity_instance]

}
