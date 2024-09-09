# https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external
#
data "external" "free-trial-kymaruntime-quota" {
  for_each = { for acc in data.btp_subaccounts.all.values : acc.id => acc if acc.name == "trial" && var.BTP_KYMA_PLAN == "trial"}

  program = ["bash", "${path.module}/free-trial-kymaruntime-quota.sh"]

  query = {
    # arbitrary map from strings to strings, passed
    # to the external program as the data query.
    username = "${var.username}"
    password = "${var.password}"
    globalaccount = "${var.globalaccount}"
    url = "https://cli.btp.cloud.sap" 
  }
}

resource "terraform_data" "replacement" {
  input = "${timestamp()}"
}


data "external" "free-trial-postgresql-quota" {
  for_each   = { for acc in data.btp_subaccounts.all.values : acc.id => acc if acc.name == "trial" && var.BTP_KYMA_PLAN == "trial"}

  depends_on = [
         terraform_data.replacement
     ]


  program = ["bash", "${path.module}/free-trial-kymaruntime-quota.sh"]

  query = {
    # arbitrary map from strings to strings, passed
    # to the external program as the data query.
    username = "${var.username}"
    password = "${var.password}"
    globalaccount = "${var.globalaccount}"
    url = "https://cli.btp.cloud.sap" 
  }
}

/*
terraform console
> local.trial_kymaruntime
{
  "32d6af28-d355-43ef-a4ff-aeaeb62bfe3e" = {
    "beta_enabled" = false
    "created_by" = ""
    "created_date" = "2024-08-13T14:06:58Z"
    "description" = ""
    "id" = "32d6af28-d355-43ef-a4ff-aeaeb62bfe3e"
    "labels" = tomap(null) 
    "last_modified" = "2024-08-13T14:07:18Z"
    "name" = "trial"
    "parent_features" = toset(null) 
    "parent_id" = "d9d2dd55-8f25-4f6f-9175-f620d8ed8412"
    "region" = "us10"
    "state" = "OK"
    "subdomain" = "2392906ftrial"
    "usage" = "UNSET"
  }
}
*/  




# look up all available subaccounts of a global account
data "btp_subaccounts" "all" {}

/*
data "btp_subaccount_environment_instances" "trial" { subaccount_id = local.trial.id }

locals {
  trial             = [for acc in data.btp_subaccounts.all.values : acc if acc.name == "trial"][*]
}


resource "btp_subaccount_entitlement" "free-trial-kymaruntime-quota" {
  for_each      = { for acc in data.btp_subaccounts.all.values : acc.id => acc if acc.name == "trial" && var.BTP_KYMA_PLAN == "trial"}

  subaccount_id = each.key # each.value.id
  service_name  = "kymaruntime"
  plan_name     = var.BTP_KYMA_PLAN
  amount        = 0 #null # https://github.com/SAP/terraform-provider-btp/issues/880
}
*/

/*
│ Cannot assign the quota for service 'kymaruntime' and service plan 'trial' to subaccount
│ 8c6eb06a-4c7d-431f-ac38-c1cf09e08d8c. The requested quota (1) exceeds the maximum allowed amount (1) for this
│ service plan across all subaccounts in this global account or directory. [Error: 30009/409]

if no amount at all...
│ 
│ Cannot assign kymaruntime with plan trial to subaccount 8c6eb06a-4c7d-431f-ac38-c1cf09e08d8c. A quota was not set
│ in the amount parameter or the enable parameter was set (setting the enable parameter is  supported only by
│ multitenant applications and by services that do not permit a numeric quota assignment). [Error: 12003/400]
*/
