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
  for_each             = toset("${var.emergency_admins}")
  subaccount_id        = data.btp_subaccount.context.id
  role_collection_name = "Subaccount Administrator"
  user_name            = each.value
}
