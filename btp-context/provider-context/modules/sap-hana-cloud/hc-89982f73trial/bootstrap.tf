
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
  launchpad_admins           = var.launchpad_admins

  service_plan__build_workzone = var.service_plan__build_workzone
  subaccount_id              = var.subaccount_id
  whitelist_ips              = ["0.0.0.0/0"]
  BTP_POSTGRESQL_PLAN        = module.provider_context.postgresql_db == {} ? "" : "trial"
  HC_ADMIN_API_ACCESS        = module.provider_context.admin_api_access == {} ? false : true
  BTP_FREE_LAUNCHPAD_QUOTA   = true
}
