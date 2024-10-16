data "btp_globalaccount" "this" {}

locals {
  params_without_mappings = {
    memory                 = var.memory
    vcpu                   = var.vcpu
    storage                = var.storage
    generateSystemPassword = true
    whitelistIPs           = var.whitelist_ips
  }
  params_with_mappings = {
    databaseMappings       = var.database_mappings
    memory                 = var.memory
    vcpu                   = var.vcpu
    storage                = var.storage
    generateSystemPassword = true
    whitelistIPs           = var.whitelist_ips
  }
}


# Extract the right entry from all entitlements
locals {

  launchpad_free = {
    for service in data.btp_globalaccount_entitlements.all.values : service.service_name => service if service.category == "QUOTA_BASED_APPLICATION" && service.plan_name == "free" && service.service_name == "SAPLaunchpad" && service.quota_remaining >=  0
  }  

  admin_api_access = {
    for service in data.btp_globalaccount_entitlements.all.values : service.service_name => service if service.plan_name == "admin-api-access" && service.service_name == "hana-cloud"

  }
}

output "launchpad_free" {
  value       = local.launchpad_free
}

output "admin_api_access" {
  value       = local.admin_api_access
}



# Extract the right entry from all entitlements
locals {

  postgresql_db = {
    for service in data.btp_globalaccount_entitlements.all.values : service.service_name => service if service.category == "SERVICE" && service.plan_name == "trial" && service.service_name == "postgresql-db"
  }

  postgresql_standard_plan = {
    for service in data.btp_globalaccount_entitlements.all.values : service.service_name => service if service.category == "SERVICE" && service.plan_name == "standard" && service.service_name == "postgresql-db"
  }
  
  BTP_POSTGRESQL_PLAN = local.postgresql_db == {} ? "" : "trial"
}

// only use the trial postresql plan, the reson being even the free postfresql plan incurs a charge
#
output "postgresql_db" {
  value       = local.postgresql_db
}

# adding postgresql-db entitlement (quota-based)
#
resource "btp_subaccount_entitlement" "postgresql" {
  count          = local.BTP_POSTGRESQL_PLAN != "trial" ? 0 : 1

  subaccount_id = data.btp_subaccount.context.id
  service_name  = "postgresql-db"
  plan_name     = "trial"
  amount        = 1
}


resource "btp_subaccount_entitlement" "hana_cloud" {
  subaccount_id = data.btp_subaccount.context.id
  service_name  = var.service_name
  plan_name     = var.plan_name
}

resource "btp_subaccount_entitlement" "hana_schema" {
  subaccount_id = data.btp_subaccount.context.id
  service_name  = "hana" 
  plan_name     = "schema"
}

resource "btp_subaccount_entitlement" "hana_hdi_container" {
  subaccount_id = data.btp_subaccount.context.id
  service_name  = "hana" 
  plan_name     = "hdi-shared" 
}

resource "btp_subaccount_entitlement" "tools" {
  subaccount_id = data.btp_subaccount.context.id
  service_name  = var.hana_cloud_tools_app_name
  plan_name     = var.hana_cloud_tools_plan_name
}

resource "btp_subaccount_role_collection_assignment" "hana_admin" {
  subaccount_id        = data.btp_subaccount.context.id
  for_each             = var.admins == null ? {} : { for user in var.admins : user => user }
  role_collection_name = "SAP HANA Cloud Administrator"
  user_name            = each.value
  depends_on = [
    btp_subaccount_subscription.hana_cloud_tools,
  ]
}

resource "btp_subaccount_role_collection_assignment" "hana_viewer" {
  subaccount_id        = data.btp_subaccount.context.id
  for_each             = var.viewers == null ? {} : { for user in var.viewers : user => user }
  role_collection_name = "SAP HANA Cloud Viewer"
  user_name            = each.value
  depends_on = [
    btp_subaccount_subscription.hana_cloud_tools,
  ]
}

resource "btp_subaccount_role_collection_assignment" "hana_security_admin" {
  subaccount_id        = data.btp_subaccount.context.id
  for_each             = var.security_admins == null ? {} : { for user in var.security_admins : user => user }
  role_collection_name = "SAP HANA Cloud Security Administrator"
  user_name            = each.value
  depends_on = [
    btp_subaccount_subscription.hana_cloud_tools,
  ]
}

resource "btp_subaccount_subscription" "hana_cloud_tools" {
  subaccount_id = data.btp_subaccount.context.id
  app_name      = var.hana_cloud_tools_app_name
  plan_name     = var.hana_cloud_tools_plan_name
  depends_on    = [btp_subaccount_entitlement.tools]

  timeouts = {
    create = "25m"
    delete = "15m"
  }  
}

data "btp_subaccount_subscription" "hana_cloud_tools_data" {
  subaccount_id = data.btp_subaccount.context.id
  app_name      = var.hana_cloud_tools_app_name
  plan_name     = var.hana_cloud_tools_plan_name
  depends_on    = [btp_subaccount_entitlement.tools]
}

data "btp_subaccount_service_plan" "my_hana_plan" {
  subaccount_id = data.btp_subaccount.context.id
  name          = var.plan_name
  offering_name = var.service_name
  depends_on = [
    btp_subaccount_entitlement.hana_cloud
  ]
}

# Create or Update an SAP HANA Cloud database instance
resource "btp_subaccount_service_instance" "my_sap_hana_cloud_instance" {
  count = var.database_mappings == null ? 1 : 0
  subaccount_id  = data.btp_subaccount.context.id
  serviceplan_id = data.btp_subaccount_service_plan.my_hana_plan.id
  name           = var.instance_name
  parameters = jsonencode({
    data = local.params_without_mappings
  })
  timeouts = {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
  depends_on = [
    btp_subaccount_subscription.hana_cloud_tools
  ]
}

resource "btp_subaccount_service_instance" "my_sap_hana_cloud_instance_with_mappings" {
  count = var.database_mappings == null ? 0 : 1
  subaccount_id  = data.btp_subaccount.context.id
  serviceplan_id = data.btp_subaccount_service_plan.my_hana_plan.id
  name           = var.instance_name
  parameters = jsonencode({
    data = local.params_with_mappings
  })
  timeouts = {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
  depends_on = [
    btp_subaccount_subscription.hana_cloud_tools
  ]
}

# look up a service instance by its name and subaccount ID
data "btp_subaccount_service_instance" "my_hana_service" {
  subaccount_id = data.btp_subaccount.context.id
  name          = var.instance_name
  depends_on = [
    btp_subaccount_service_instance.my_sap_hana_cloud_instance[0]
  ]
}


# create a service binding in a subaccount
resource "btp_subaccount_service_binding" "hc_binding_dbadmin" {
  subaccount_id       = data.btp_subaccount.context.id
  service_instance_id = data.btp_subaccount_service_instance.my_hana_service.id
  name                = "hc-binding-dbadmin"
  parameters = jsonencode({
    scope           = "administration"
    credential-type = "PASSWORD_GENERATED"
  })
  depends_on = [
    btp_subaccount_service_instance.my_sap_hana_cloud_instance[0]
  ]
}


# create a service binding in a subaccount
resource "btp_subaccount_service_binding" "hc_binding" {
  subaccount_id       = data.btp_subaccount.context.id
  service_instance_id = data.btp_subaccount_service_instance.my_hana_service.id
  name                = "hc-binding"
  depends_on = [
    btp_subaccount_service_instance.my_sap_hana_cloud_instance[0]
  ]
}

# create a parameterized service binding in a subaccount
resource "btp_subaccount_service_binding" "hc_binding_x509" {
  subaccount_id       = data.btp_subaccount.context.id
  service_instance_id = data.btp_subaccount_service_instance.my_hana_service.id
  name                = "hc-binding-x509"
  parameters = jsonencode({
    credential-type = "x509"
    x509 = {    "key-length": 4096,"validity": 365,"validity-type": "DAYS" }
  })
  depends_on = [
    btp_subaccount_service_instance.my_sap_hana_cloud_instance[0]
  ]
}


data "btp_subaccount_service_plan" "dest_lite" {
  subaccount_id = data.btp_subaccount.context.id
  name          = "lite"
  offering_name = "destination"

  depends_on    = [btp_subaccount_entitlement.destination]
}


resource "btp_subaccount_service_instance" "dest_bootstrap" {
  depends_on     = [btp_subaccount_entitlement.destination]

  subaccount_id  = data.btp_subaccount.context.id
  serviceplan_id = data.btp_subaccount_service_plan.dest_lite.id
  name           = "dest_bootstrap"
}

resource "btp_subaccount_service_instance" "dest_provider" {
  depends_on = [
    btp_subaccount_entitlement.destination,
    btp_subaccount_service_instance.my_sap_hana_cloud_instance[0],
    btp_subaccount_service_binding.dest_binding
  ]

  subaccount_id  = data.btp_subaccount.context.id
  serviceplan_id = data.btp_subaccount_service_plan.dest_lite.id
  name           = "dest_provider"
  parameters     = jsonencode({

    "init_data": {
        "subaccount": {
            "destinations": [
                  {
                    "Description": "dest-httpbin",
                    "Type": "HTTP",
                    "clientId": "${local.dest-secret.clientid}",
                    "HTML5.DynamicDestination": "true",
                    "HTML5.Timeout": "60000",
                    "Authentication": "OAuth2ClientCredentials",
                    "Name": "dest-httpbin",
                    "tokenServiceURL": "${local.dest-secret.url}/oauth/token",
                    "ProxyType": "Internet",
                    "URL": "https://httpbin.org",
                    "tokenServiceURLType": "Dedicated",
                    "clientSecret": "${local.dest-secret.clientsecret}"
                  },
                  {
                    "Description": "SAP Destination Service APIs",
                    "Type": "HTTP",
                    "clientId": "${local.dest-secret.clientid}",
                    "HTML5.DynamicDestination": "true",
                    "HTML5.Timeout": "60000",
                    "Authentication": "OAuth2ClientCredentials",
                    "Name": "destination-service",
                    "tokenServiceURL": "${local.dest-secret.url}/oauth/token",
                    "ProxyType": "Internet",
                    "URL": "${local.dest-secret.uri}/destination-configuration/v1",
                    "tokenServiceURLType": "Dedicated",
                    "clientSecret": "${local.dest-secret.clientsecret}"
                  },
                  {
                    "Description": "hc-httpbin",
                    "Type": "HTTP",
                    "clientId": "${local.hc-secret.clientid}",
                    "HTML5.DynamicDestination": "true",
                    "HTML5.Timeout": "60000",
                    "Authentication": "OAuth2ClientCredentials",
                    "Name": "hc-httpbin",
                    "tokenServiceURL": "${local.hc-secret.url}/oauth/token",
                    "ProxyType": "Internet",
                    "URL": "https://httpbin.org",
                    "tokenServiceURLType": "Dedicated",
                    "clientSecret": "${local.hc-secret.clientsecret}"
                  },
                  {
                    "Description": "SAP HANA Cloud Management APIs",
                    "Type": "HTTP",
                    "clientId": "${local.hc-secret.clientid}",
                    "HTML5.DynamicDestination": "true",
                    "HTML5.Timeout": "60000",
                    "Authentication": "OAuth2ClientCredentials",
                    "Name": "hc-services",
                    "tokenServiceURL": "${local.hc-secret.url}/oauth/token",
                    "ProxyType": "Internet",
                    "URL": "${local.hc-api}",
                    "tokenServiceURLType": "Dedicated",
                    "clientSecret": "${local.hc-secret.clientsecret}"
                  },         
                  {
                    "Description": "hc-httpbin-x509",
                    "Type": "HTTP",
                    "clientId": "${local.hc-x509.clientid}",
                    "HTML5.DynamicDestination": "true",
                    "HTML5.Timeout": "60000",
                    "Authentication": "OAuth2ClientCredentials",
                    "Name": "hc-httpbin-x509",
                    "tokenServiceURL": "${local.hc-x509.certurl}/oauth/token",
                    "ProxyType": "Internet",
                    "URL": "https://httpbin.org",
                    "tokenServiceURLType": "Dedicated",
                    "tokenService.KeyStoreLocation": "hc-x509.p12",
                    "tokenService.KeyStorePassword": "Password1"
                  },
                  {
                    "Description": "SAP HANA Cloud Management APIs with x509",
                    "Type": "HTTP",
                    "clientId": "${local.hc-x509.clientid}",
                    "HTML5.DynamicDestination": "true",
                    "HTML5.Timeout": "60000",
                    "Authentication": "OAuth2ClientCredentials",
                    "Name": "hc-services-x509",
                    "tokenServiceURL": "${local.hc-x509.certurl}/oauth/token",
                    "ProxyType": "Internet",
                    "URL": "${local.hc-api}",
                    "tokenServiceURLType": "Dedicated",
                    "tokenService.KeyStoreLocation": "hc-x509.p12",
                    "tokenService.KeyStorePassword": "Password1"
                  }         

            ],
           "certificates": [
               "${local.hc-x509-p12}"
           ],

            "existing_certificates_policy": "update",
            "existing_destinations_policy": "update"           
       }
   }
  
  })

  timeouts = {
    create = "25m"
    update = "15m"
    delete = "15m"
  }
/*
  lifecycle {
    replace_triggered_by = [
      btp_subaccount_service_binding.dest_binding
    ]
  }
*/

}

# create a service binding in a subaccount
resource "btp_subaccount_service_binding" "dest_binding" {
  subaccount_id       = data.btp_subaccount.context.id
  service_instance_id = btp_subaccount_service_instance.dest_bootstrap.id
  name                = "dest-binding"

  depends_on = [
    btp_subaccount_service_instance.dest_bootstrap
  ]
}

/*
# create a service binding data source
data "btp_subaccount_service_binding" "dest_binding_data" {
  subaccount_id       = data.btp_subaccount.context.id
  name                = "dest-binding"
    
  depends_on = [
    btp_subaccount_service_binding.dest_binding
  ]
}
*/

locals {
  dest-secret = jsondecode(btp_subaccount_service_binding.dest_binding.credentials)
}

locals {
  hc-secret = jsondecode(btp_subaccount_service_binding.hc_binding.credentials)["uaa"]
}

# https://stackoverflow.com/questions/52350446/terraform-split-variable-value-into-2
#
locals {
  elem1 = "${element(split(".", jsondecode(btp_subaccount_service_binding.hc_binding.credentials)["host"]),2)}"
  elem2 = "${element(split(".", jsondecode(btp_subaccount_service_binding.hc_binding.credentials)["host"]),3)}"
  elem3 = "${element(split(".", jsondecode(btp_subaccount_service_binding.hc_binding.credentials)["host"]),4)}"
  elem4 = "${element(split(".", jsondecode(btp_subaccount_service_binding.hc_binding.credentials)["host"]),5)}"

  hc-api = "https://api.gateway.orchestration.${join(".", [local.elem1,local.elem2,local.elem3,local.elem4])}"
}

locals {
  hc-x509 = jsondecode(btp_subaccount_service_binding.hc_binding_x509.credentials)["uaa"]
}


locals {
  is_windows = length(regexall("^[a-z]:", lower(abspath(path.root)))) > 0
}

output "absolute_path" {
    value = abspath(path.root)
}

output "operating_system" {
    value = local.is_windows ? "Windows" : "Linux"
}

/*
# https://stackoverflow.com/a/15490765
# https://unix.stackexchange.com/a/672640
#
resource "terraform_data" "openssl_cert" {
  triggers_replace = {
    always_run = "${timestamp()}"
  }
 provisioner "local-exec" {
   interpreter = ["/bin/bash", "-c"]
   command = <<EOF
      ( \
      set -e -o pipefail ;\
      ISSUER=$(terraform output -json hc_credentials_x509 | jq -r '.uaa | {clientid, key, certificate, url: (.certurl+ "/oauth/token") }' ) ;\
      KEYSTORE=$(openssl pkcs12 -export \
      -in <(echo "$(jq  -r '. | .certificate' <<< $ISSUER )") \
      -inkey <(echo "$(jq  -r '. | .key' <<< $ISSUER )") \
      -passout pass:Password1 | base64)   ;\
      echo $KEYSTORE ;\
      openssl pkcs12 -nokeys -info -in <(echo -n $KEYSTORE | base64 -di) -passin pass:Password1 ;\
      )
   EOF
 }
}
*/

# https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external
#
data "external" "openssl_cert" {
  program = ["bash", "${path.module}/openssl-cert.sh"]

  query = {
    # arbitrary map from strings to strings, passed
    # to the external program as the data query.
    clientid = "${local.hc-x509.clientid}"
    key = "${local.hc-x509.key}"    
    certificate = "${local.hc-x509.certificate}" 
    url = "${local.hc-x509.certurl}/oauth/token" 
    location = "hc-x509.p12"
  }
}


# https://stackoverflow.com/a/15490765
# https://unix.stackexchange.com/a/672640
#
locals {
  //hc-x509-p12 = data.external.openssl_cert.result

  // base64 behaves differently on linux and the encoded output has newline characters
  // base64 -w 0 would do suppress the newlines however it is not supported on OsX
  // 
  Content = replace(data.external.openssl_cert.result.Content, "\n", "")
  Name    = data.external.openssl_cert.result.Name
  Type    = data.external.openssl_cert.result.Type

   hc-x509-p12 = tomap({
          "Content" = local.Content
           "Name" = local.Name
           "Type" = local.Type
          })
}

output "hc-x509-p12" {
  value = nonsensitive(local.hc-x509-p12)
}

output "dest-httpbin" {
  value       = "${local.sap_approuter_dynamic_dest}/dest-httpbin/headers"
  description = "dest-httpbin"
}

output "subaccountDestinations" {
  value       = "${local.sap_approuter_dynamic_dest}/destination-service/subaccountDestinations"
  description = "destination-service: subaccountDestinations"
}

output "instanceDestinations" {
  value       = "${local.sap_approuter_dynamic_dest}/destination-service/instanceDestinations"
  description = "destination-service: instanceDestinations"
}

output "hc-metrics" {
  value       = "${local.sap_approuter_dynamic_dest}/hc-services/metrics/v1/serviceInstances/${data.btp_subaccount_service_instance.my_hana_service.id}/values"
  description = "SAP HANA Cloud Management APIs"
}
output "hc-alerts" {
  value       = "${local.sap_approuter_dynamic_dest}/hc-services/alerts/v1/serviceInstances/${data.btp_subaccount_service_instance.my_hana_service.id}/events?alertState=All&severity=INFO,NOTICE,WARNING,ERROR"
  description = "SAP HANA Cloud Management APIs"
}
