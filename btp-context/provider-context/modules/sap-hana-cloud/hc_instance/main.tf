
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



module "sap_hana_cloud" {
  source                     = "../../sap-hana-cloud"
  service_name               = var.service_name
  plan_name                  = var.plan_name
  hana_cloud_tools_app_name  = var.hana_cloud_tools_app_name
  hana_cloud_tools_plan_name = var.hana_cloud_tools_plan_name

  memory                     = var.memory
  vcpu                       = var.vcpu
  storage                    = var.storage

  instance_name              = var.instance_name
  admins                     = var.admins
  subaccount_id              = data.btp_subaccount.context.id
  whitelist_ips              = ["0.0.0.0/0"]
}
