
module "runtime_context" {
  source             = "../../kyma-runtime"
##  source             = "github.com/ptesny/btp-automation/btp-context/runtime-context/modules/kyma-runtime"

  BTP_GLOBAL_ACCOUNT = var.BTP_GLOBAL_ACCOUNT
  BTP_BOT_USER       = var.BTP_BOT_USER
  BTP_SA_REGION      = var.BTP_SA_REGION
  BTP_SUBACCOUNT     = var.BTP_SUBACCOUNT
  BTP_BOT_PASSWORD   = var.BTP_BOT_PASSWORD
  BTP_CUSTOM_IDP     = var.BTP_CUSTOM_IDP
  BTP_BACKEND_URL    = var.BTP_BACKEND_URL
   
  emergency_admins   = var.emergency_admins
  launchpad_admins   = var.launchpad_admins
  cluster_admins     = var.cluster_admins

  BTP_KYMA_DRY_RUN   = var.BTP_KYMA_DRY_RUN
  BTP_KYMA_PLAN      = var.BTP_KYMA_PLAN
  BTP_KYMA_NAME      = var.BTP_KYMA_NAME
  BTP_KYMA_REGION    = var.BTP_KYMA_REGION

  service_plan__build_workzone = var.service_plan__build_workzone

  argocd_username    = var.argocd_username
  argocd_password    = var.argocd_password
  argocd_tokenurl    = var.argocd_tokenurl
  argocd_clientid    = var.argocd_clientid

  argocd_url         = var.argocd_url
  
  provider_state_suffix = var.provider_state_suffix
}
