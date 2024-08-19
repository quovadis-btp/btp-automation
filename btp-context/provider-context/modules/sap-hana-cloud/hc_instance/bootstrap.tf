
#
module "provider_context" {
  source                     = "../../sap-hana-cloud"

  globalaccount              = var.globalaccount
  username                   = var.username
  subdomain                  = var.subdomain
  subaccount_name            = var.subaccount_name 
  region                     = var.region
  password                   = var.password
  idp                        = var.idp

  service_name               = var.service_name
  plan_name                  = var.plan_name
  hana_cloud_tools_app_name  = var.hana_cloud_tools_app_name
  hana_cloud_tools_plan_name = var.hana_cloud_tools_plan_name

  memory                     = var.memory
  vcpu                       = var.vcpu
  storage                    = var.storage

  instance_name              = var.instance_name
  admins                     = var.admins
  emergency_admins           = var.emergency_admins
  subaccount_id              = var.subaccount_id
  whitelist_ips              = ["0.0.0.0/0"]
}
