
module "custom_idp" {
  source             = "../../custom-idp"

  globalaccount      = var.globalaccount
  username           = var.username
  password           = var.password
  region             = var.region
  subaccount_name    = var.subaccount_name
  subdomain          = var.subdomain
  emergency_admins   = var.emergency_admins
  platform_admins    = var.platform_admins
  BTP_KYMA_PLAN      = var.BTP_KYMA_PLAN
}
