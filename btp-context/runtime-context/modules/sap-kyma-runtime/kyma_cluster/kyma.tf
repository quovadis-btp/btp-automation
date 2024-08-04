resource "btp_subaccount" "this" {
  name      = var.subaccount_name
  subdomain = var.subdomain
  region    = var.region
}

module "sap_kyma_runtime" {
  source         = "../../sap-kyma-runtime" 
  name           = var.name
  administrators = var.administrators
  subaccount_id  = btp_subaccount.this.id
}
