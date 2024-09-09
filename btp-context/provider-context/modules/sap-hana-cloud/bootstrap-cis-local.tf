
resource "btp_subaccount_entitlement" "cis" {
  subaccount_id = data.btp_subaccount.context.id
  service_name  = "cis"
  plan_name     = "local"
}

data "btp_subaccount_service_plan" "cis" {
  depends_on     = [btp_subaccount_entitlement.cis]

  subaccount_id = data.btp_subaccount.context.id
  offering_name = "cis"
  name          = "local"
}


resource "btp_subaccount_service_instance" "cis-local" {
  depends_on     = [btp_subaccount_entitlement.cis]

  subaccount_id  = data.btp_subaccount.context.id
  name           = "cis-local"
  serviceplan_id = data.btp_subaccount_service_plan.cis.id

  parameters = jsonencode({
      "grantType": "clientCredentials"
  })
}

resource "btp_subaccount_service_binding" "cis-local-binding" {
  depends_on          = [btp_subaccount_service_instance.cis-local]

  subaccount_id       = data.btp_subaccount.context.id
  name                = "cis-local-binding"
  service_instance_id = btp_subaccount_service_instance.cis-local.id
}

locals {
  cis-secret = jsondecode(btp_subaccount_service_binding.cis-local-binding.credentials)
}

resource "local_sensitive_file" "cis-secret" {
  content = jsonencode({
    clientid     = local.cis-secret.uaa.clientid
    clientsecret = local.cis-secret.uaa.clientsecret  
    url          = "${local.cis-secret.uaa.url}/oauth/token"
  })
  filename = "cis-secret.json"
}


resource "btp_subaccount_entitlement" "destination" {
  subaccount_id = data.btp_subaccount.context.id
  service_name  = "destination"
  plan_name     = "lite"
}

data "btp_subaccount_service_plan" "destination" {
  depends_on     = [btp_subaccount_entitlement.destination]

  subaccount_id = data.btp_subaccount.context.id
  offering_name = "destination"
  name          = "lite"
}


resource "btp_subaccount_service_instance" "dest-local" {
  depends_on     = [btp_subaccount_entitlement.destination, btp_subaccount_service_binding.cis-local-binding]

  subaccount_id  = data.btp_subaccount.context.id
  name           = "dest-local"
  serviceplan_id = data.btp_subaccount_service_plan.destination.id

  parameters = jsonencode({

    "init_data": {
        "subaccount": {
            "destinations": [
                  {
                    "Description": "cis-httpbin",
                    "Type": "HTTP",
                    "clientId": "${local.cis-secret.uaa.clientid}",
                    "HTML5.DynamicDestination": "true",
                    "HTML5.Timeout": "60000",
                    "Authentication": "OAuth2ClientCredentials",
                    "Name": "cis-httpbin",
                    "tokenServiceURL": "${local.cis-secret.uaa.url}/oauth/token",
                    "ProxyType": "Internet",
                    "URL": "https://httpbin.org",
                    "tokenServiceURLType": "Dedicated",
                    "clientSecret": "${local.cis-secret.uaa.clientsecret}"
                  },
                  {
                    "Description": "SAP Cloud Management Service APIs (provisioning_service_url)",
                    "Type": "HTTP",
                    "clientId": "${local.cis-secret.uaa.clientid}",
                    "HTML5.DynamicDestination": "true",
                    "HTML5.Timeout": "60000",
                    "Authentication": "OAuth2ClientCredentials",
                    "Name": "provisioning-service",
                    "tokenServiceURL": "${local.cis-secret.uaa.url}/oauth/token",
                    "ProxyType": "Internet",
                    "URL": "${local.cis-secret.endpoints.provisioning_service_url}",
                    "tokenServiceURLType": "Dedicated",
                    "clientSecret": "${local.cis-secret.uaa.clientsecret}"
                  },         
                  {
                    "Description": "SAP Cloud Management Service APIs (saas_registry_service_url)",
                    "Type": "HTTP",
                    "clientId": "${local.cis-secret.uaa.clientid}",
                    "HTML5.DynamicDestination": "true",
                    "HTML5.Timeout": "60000",
                    "Authentication": "OAuth2ClientCredentials",
                    "Name": "saas-registry-service",
                    "tokenServiceURL": "${local.cis-secret.uaa.url}/oauth/token",
                    "ProxyType": "Internet",
                    "URL": "${local.cis-secret.endpoints.saas_registry_service_url}",
                    "tokenServiceURLType": "Dedicated",
                    "clientSecret": "${local.cis-secret.uaa.clientsecret}"
                  }         
            ],
           "certificates": [
           ],

            "existing_certificates_policy": "update",
            "existing_destinations_policy": "update"           
       }
   }

  })
}

locals {
  service_name__sap_build_apps = "sap-build-apps"
  service_name__build_workzone = "SAPLaunchpad"
}

/*
TODO: need to check if there is enough free SAPLaunchpad service quota

launchpad_free = {
  "SAPLaunchpad" = {
    "category" = "QUOTA_BASED_APPLICATION"
    "plan_description" = "The free plan has quota restrictions. Please note, only community support is available for free service plans and these are not subject to SLAs. Use of free tier service plans are subject to additional terms and conditions as provided in the Business Technology Platform Supplemental Terms and Conditions linked in the Additional Links tab displayed in the Service tile."
    "plan_display_name" = "free"
    "plan_name" = "free"
    "quota_assigned" = 1
    "quota_remaining" = 0
    "service_display_name" = "SAP Build Work Zone, standard edition"
    "service_name" = "SAPLaunchpad"
  }
}

in order to mitigate the following error message:

╷
│ Error: API Error Creating Resource Entitlement (Subaccount)
│ 
│ Cannot assign the quota for service 'SAPLaunchpad' and service plan 'free' to subaccount da63f705-0009-4f6f-a5ef-f543747c7d1a. The requested
│ quota (1) exceeds the maximum allowed amount (2) for this service plan across all subaccounts in this global account or directory. [Error:
│ 30009/409]
╵
https://stackoverflow.com/questions/58594506/how-to-for-each-through-a-listobjects-in-terraform-0-12

https://github.com/recognizegroup/terraform/tree/develop/modules

https://developer.hashicorp.com/terraform/tutorials/configuration-language/for-each

*/
data "btp_subaccounts" "all" {}
data "btp_globalaccount_entitlements" "all" {}

locals {
  
  free_entitlements = { 
    for service in data.btp_globalaccount_entitlements.all.values : service.service_name => service if service.category == "SERVICE" && service.plan_name == "free"
  }
}

output "free_entitlements" {
  value = local.free_entitlements
}

resource "btp_subaccount_entitlement" "build_workzone" {
  count         = var.BTP_FREE_LAUNCHPAD_QUOTA ? 1 : 0

  subaccount_id = data.btp_subaccount.context.id
  service_name  = local.service_name__build_workzone
  plan_name     = var.service_plan__build_workzone
  amount        = var.service_plan__build_workzone == "free" ? 1 : null
}

# Create app subscription to SAP Build Workzone, standard edition (depends on entitlement)
resource "btp_subaccount_subscription" "build_workzone" {
  count         = var.BTP_FREE_LAUNCHPAD_QUOTA ? 1 : 0

  subaccount_id = data.btp_subaccount.context.id
  app_name      = local.service_name__build_workzone
  plan_name     = var.service_plan__build_workzone
  depends_on    = [btp_subaccount_entitlement.build_workzone]

  /*
  timeouts = {
    create = "25m"
    delete = "15m"
  }
  */
}

# Assign users to Role Collection: Launchpad_Admin
resource "btp_subaccount_role_collection_assignment" "launchpad_admin" {
  for_each             = var.BTP_FREE_LAUNCHPAD_QUOTA == true ? toset("${var.launchpad_admins}") : {}
  subaccount_id        = data.btp_subaccount.context.id
  role_collection_name = "Launchpad_Admin"
  user_name            = each.value
  depends_on           = [btp_subaccount_subscription.build_workzone]
}

data "btp_subaccount_subscription" "build_workzone" {
  count         = var.BTP_FREE_LAUNCHPAD_QUOTA ? 1 : 0

  depends_on    = [btp_subaccount_subscription.build_workzone]

  subaccount_id = data.btp_subaccount.context.id
  app_name      = local.service_name__build_workzone
  plan_name     = var.service_plan__build_workzone

}

# https://stackoverflow.com/a/74460150
locals {
  subscription_url = one(data.btp_subaccount_subscription.build_workzone[*].subscription_url)
}

output "sap_build_workzone_subscription_url" {
  value       = local.subscription_url != null ? local.subscription_url : ""
  description = "SAP Build Workzone subscription URL."
}

locals {
  sap_approuter_dynamic_dest = local.subscription_url != null ? "${replace(local.subscription_url, ".dt", "")}/dynamic_dest" : ""
}

output "httpbin_headers_url" {
  value       = "${local.sap_approuter_dynamic_dest}/cis-httpbin/headers"
  description = "HTTPBIN headers."
}

output "provisioning_service_environments_url" {
  value       = "${local.sap_approuter_dynamic_dest}/provisioning-service/provisioning/v1/environments"
  description = "SAP Cloud Management Service APIs (provisioning_service_url)."
}
