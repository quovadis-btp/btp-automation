

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

resource "local_file" "subaccount_id" {
  content  = data.btp_subaccount.context.id
  filename = "subaccount_id.txt"
}

resource "btp_subaccount_role_collection_assignment" "subaccount_users" {
  for_each             = toset("${var.emergency_admins}")
  subaccount_id        = data.btp_subaccount.context.id
  role_collection_name = "Subaccount Administrator"
  user_name            = each.value
}


## bootstrap custom idp trust for the provider subaccount


# custom identity provider
data "btp_globalaccount_trust_configuration" "custom" {
  origin = var.origin == "" ? "sap.custom" :  var.origin
}


# look up user details which belongs to a custom identity provider on global account level
data "btp_globalaccount_user" "quovadis" {
  user_name = var.username
  origin = var.origin == "" ? "sap.custom" :  var.origin
}

/*
resource "btp_subaccount_entitlement" "identity" {
  count = var.idp == "" ? 1 : 0

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
  parameters = jsonencode({
    cloud_service = "PROD"
  })
}
*/

# default identity provider
data "btp_subaccount_trust_configuration" "default" {
  subaccount_id = data.btp_subaccount.context.id
  origin        = "sap.default"
}

/*
# custom identity provider
data "btp_subaccount_trust_configuration" "custom" {
  subaccount_id = data.btp_subaccount.context.id
  origin        = "sap.custom"
}
*/

resource "btp_subaccount_trust_configuration" "custom_idp" {
  subaccount_id     = data.btp_subaccount.context.id
  identity_provider = var.idp != "" ? var.idp : data.btp_globalaccount_trust_configuration.custom.identity_provider
  
  name              = "${local.subaccount_name}"
}
