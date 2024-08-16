resource "random_uuid" "uuid" {}

# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id
resource "random_id" "context_id" {
  byte_length = 4
  prefix      = "quovadis-"
}

locals {
  random_uuid       = random_uuid.uuid.result
  context_id        = random_id.context_id.hex
  subaccount_domain = lower("${var.BTP_SUBACCOUNT}-${local.context_id}")
  subaccount_name   = lower("${var.BTP_SUBACCOUNT}-${local.context_id}")
  #subaccount_domain = lower("${var.BTP_SUBACCOUNT}-${local.random_uuid}")
  #subaccount_name   = lower("${var.BTP_SUBACCOUNT}-${local.random_uuid}")
  region            = lower("${var.BTP_SA_REGION}")
}

###############################################################################################
# Creation of a subaccount: make bootstrap-k8s
# https://github.com/SAP-samples/btp-terraform-samples/blob/main/released/discovery_center/mission_3061/step1/main.tf#L6
###############################################################################################
resource "btp_subaccount" "create_subaccount" {
  count     = var.subaccount_id == "" ? 1 : 0

  name        = local.subaccount_name
  subdomain   = local.subaccount_domain
  region      = local.region
  usage       = "USED_FOR_PRODUCTION"
  description = "${local.subaccount_name} is a runtime context depleted subaccount"
  labels      = {
      "${var.BTP_SUBACCOUNT}" = [""]
  } 
}

data "btp_subaccount" "context" {
  depends_on  = [btp_subaccount.create_subaccount]
  id = var.subaccount_id != "" ? var.subaccount_id : btp_subaccount.create_subaccount[0].id
}

resource "local_file" "subaccount_id" {
  content  = data.btp_subaccount.context.id
  filename = "subaccount_id.txt"
}


###############################################################################################
# Assignment of emergency admins to the sub account as sub account administrators
###############################################################################################
resource "btp_subaccount_role_collection_assignment" "subaccount_users" {
  #
  # https://github.com/SAP/terraform-provider-btp/issues/345
  /*
╷
│ Error: API Error Deleting Resource Role Collection Assignment (Subaccount)
│ 
│ Cannot delete last admin user of subaccount.
╵
  */
  depends_on           = [data.btp_subaccount.context, btp_subaccount_trust_configuration.custom_idp]

  for_each             = toset("${var.emergency_admins}")
  subaccount_id        = data.btp_subaccount.context.id
  role_collection_name = "Subaccount Administrator"
  user_name            = each.value
  origin               = btp_subaccount_trust_configuration.custom_idp.origin
}

# custom identity provider
data "btp_subaccount_trust_configuration" "custom_idp" {
  depends_on    = [btp_subaccount_trust_configuration.custom_idp]
  subaccount_id = data.btp_subaccount.context.id
  origin        = btp_subaccount_trust_configuration.custom_idp.origin
}

/*
# custom identity provider
data "btp_globalaccount_trust_configuration" "custom" {
  origin = var.origin
}


resource "btp_subaccount_trust_configuration" "custom_idp" {
  subaccount_id     = data.btp_subaccount.context.id
  identity_provider = var.idp != "" ? var.idp : data.btp_globalaccount_trust_configuration.custom.identity_provider
  
  name              = "${local.subaccount_name}"
}


*/


resource "btp_subaccount_entitlement" "identity" {
  count         = var.BTP_CUSTOM_IDP == "" ? 1 : 0

  subaccount_id = data.btp_subaccount.context.id
  service_name  = "sap-identity-services-onboarding"
  plan_name     = "default"
}

resource "btp_subaccount_subscription" "identity_instance" {
  depends_on    = [btp_subaccount_entitlement.identity]
  count         = var.BTP_CUSTOM_IDP == "" ? 1 : 0

  subaccount_id = data.btp_subaccount.context.id
  app_name      = "sap-identity-services-onboarding"
  plan_name     = "default"
  parameters    = jsonencode({
    cloud_service = "PROD"
  })
}

resource "btp_subaccount_trust_configuration" "custom_idp" {
  subaccount_id     = data.btp_subaccount.context.id
  identity_provider = var.BTP_CUSTOM_IDP != "" ? var.BTP_CUSTOM_IDP : element(split("/", btp_subaccount_subscription.identity_instance[0].subscription_url), 2)
  name              = "${local.subaccount_domain}"

  depends_on        = [btp_subaccount_subscription.identity_instance]

}