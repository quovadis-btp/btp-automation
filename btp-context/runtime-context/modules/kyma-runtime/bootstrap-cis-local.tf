
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


resource "btp_subaccount_entitlement" "build_workzone" {
  subaccount_id = data.btp_subaccount.context.id
  service_name  = local.service_name__build_workzone
  plan_name     = var.service_plan__build_workzone
  #amount        = var.service_plan__build_workzone == "free" ? 1 : null
}

# Create app subscription to SAP Build Workzone, standard edition (depends on entitlement)
resource "btp_subaccount_subscription" "build_workzone" {
  subaccount_id = data.btp_subaccount.context.id
  app_name      = local.service_name__build_workzone
  plan_name     = var.service_plan__build_workzone
  depends_on    = [btp_subaccount_entitlement.build_workzone]
}

# Assign users to Role Collection: Launchpad_Admin
resource "btp_subaccount_role_collection_assignment" "launchpad_admin" {
  for_each             = toset("${var.emergency_admins}")
  subaccount_id        = data.btp_subaccount.context.id
  role_collection_name = "Launchpad_Admin"
  user_name            = each.value
  depends_on           = [btp_subaccount_subscription.build_workzone]
}

data "btp_subaccount_subscription" "build_workzone" {
  subaccount_id = data.btp_subaccount.context.id
  app_name      = local.service_name__build_workzone
  plan_name     = var.service_plan__build_workzone
  depends_on    = [btp_subaccount_subscription.build_workzone]
}

output "sap_build_workzone_subscription_url" {
  value       = data.btp_subaccount_subscription.build_workzone.subscription_url
  description = "SAP Build Workzone subscription URL."
}

locals {
  sap_approuter_dynamic_dest = "${replace(data.btp_subaccount_subscription.build_workzone.subscription_url, ".dt", "")}/dynamic_dest"
}

output "httpbin_headers_url" {
  value       = "${local.sap_approuter_dynamic_dest}/cis-httpbin/headers"
  description = "HTTPBIN headers."
}

output "provisioning_service_environments_url" {
  value       = "${local.sap_approuter_dynamic_dest}/provisioning-service/provisioning/v1/environments"
  description = "SAP Cloud Management Service APIs (provisioning_service_url)."
}
