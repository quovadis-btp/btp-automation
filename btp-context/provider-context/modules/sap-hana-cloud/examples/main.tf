resource "btp_subaccount" "this" {
  name      = var.subaccount_name
  subdomain = var.subdomain
  region    = var.region
}

module "sap_hana_cloud" {
  source                     = "github.com/ptesny/terraform-sap-hana-cloud"
  service_name               = var.service_name
  plan_name                  = var.plan_name
  hana_cloud_tools_app_name  = var.hana_cloud_tools_app_name
  hana_cloud_tools_plan_name = var.hana_cloud_tools_plan_name

  memory                     = var.memory
  vcpu                       = var.vcpu
  storage                    = var.storage

  instance_name              = var.instance_name
  admins                     = var.admins
  subaccount_id              = btp_subaccount.this.id
  whitelist_ips              = ["0.0.0.0/0"]
}
