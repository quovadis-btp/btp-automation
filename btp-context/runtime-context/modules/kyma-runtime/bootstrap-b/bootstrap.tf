
module "runtime_context" {
  source             = "../../kyma-runtime"

  BTP_GLOBAL_ACCOUNT = var.BTP_GLOBAL_ACCOUNT
  BTP_BOT_USER       = var.BTP_BOT_USER
  BTP_SA_REGION      = var.BTP_SA_REGION
  BTP_SUBACCOUNT     = var.BTP_SUBACCOUNT
  BTP_BOT_PASSWORD   = var.BTP_BOT_PASSWORD
  BTP_CUSTOM_IDP     = var.BTP_CUSTOM_IDP
  BTP_BACKEND_URL    = var.BTP_BACKEND_URL
  BTP_KYMA_PLAN      = var.BTP_KYMA_PLAN
   
  emergency_admins   = var.emergency_admins
  launchpad_admins   = var.launchpad_admins
  cluster_admins     = var.cluster_admins

  BTP_KYMA_DRY_RUN   = var.BTP_KYMA_DRY_RUN

  service_plan__build_workzone = var.service_plan__build_workzone
}