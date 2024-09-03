
module "argocdaas" {
  source             = "../../argocdaas"

  globalaccount      = var.globalaccount
  username           = var.username
  password           = var.password
  region             = var.region
  subaccount_name    = var.subaccount_name
  subdomain          = var.subdomain
  emergency_admins   = var.emergency_admins
  platform_admins    = var.platform_admins
  BTP_ARGOCDAAS_PLAN      = var.BTP_ARGOCDAAS_PLAN
  subaccount_id      = var.subaccount_id
  idp                = var.idp
}
