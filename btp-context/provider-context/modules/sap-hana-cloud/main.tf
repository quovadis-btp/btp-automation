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

resource "btp_subaccount_entitlement" "hana_cloud" {
  subaccount_id = var.subaccount_id
  service_name  = var.service_name
  plan_name     = var.plan_name
}

resource "btp_subaccount_entitlement" "tools" {
  subaccount_id = var.subaccount_id
  service_name  = var.hana_cloud_tools_app_name
  plan_name     = var.hana_cloud_tools_plan_name
}

resource "btp_subaccount_entitlement" "destination" {
  subaccount_id = var.subaccount_id
  service_name  = "destination"
  plan_name     = "lite"
}


resource "btp_subaccount_role_collection_assignment" "hana_admin" {
  subaccount_id        = var.subaccount_id
  for_each             = var.admins == null ? {} : { for user in var.admins : user => user }
  role_collection_name = "SAP HANA Cloud Administrator"
  user_name            = each.value
  depends_on = [
    btp_subaccount_subscription.hana_cloud_tools,
  ]
}

resource "btp_subaccount_role_collection_assignment" "hana_viewer" {
  subaccount_id        = var.subaccount_id
  for_each             = var.viewers == null ? {} : { for user in var.viewers : user => user }
  role_collection_name = "SAP HANA Cloud Viewer"
  user_name            = each.value
  depends_on = [
    btp_subaccount_subscription.hana_cloud_tools,
  ]
}

resource "btp_subaccount_role_collection_assignment" "hana_security_admin" {
  subaccount_id        = var.subaccount_id
  for_each             = var.security_admins == null ? {} : { for user in var.security_admins : user => user }
  role_collection_name = "SAP HANA Cloud Security Administrator"
  user_name            = each.value
  depends_on = [
    btp_subaccount_subscription.hana_cloud_tools,
  ]
}

resource "btp_subaccount_subscription" "hana_cloud_tools" {
  subaccount_id = var.subaccount_id
  app_name      = var.hana_cloud_tools_app_name
  plan_name     = var.hana_cloud_tools_plan_name
  depends_on    = [btp_subaccount_entitlement.tools]
}

data "btp_subaccount_subscription" "hana_cloud_tools_data" {
  subaccount_id = var.subaccount_id
  app_name      = var.hana_cloud_tools_app_name
  plan_name     = var.hana_cloud_tools_plan_name
  depends_on    = [btp_subaccount_entitlement.tools]
}

data "btp_subaccount_service_plan" "my_hana_plan" {
  subaccount_id = var.subaccount_id
  name          = var.plan_name
  offering_name = var.service_name
  depends_on = [
    btp_subaccount_entitlement.hana_cloud
  ]
}

# Create or Update an SAP HANA Cloud database instance
resource "btp_subaccount_service_instance" "my_sap_hana_cloud_instance" {
  count = var.database_mappings == null ? 1 : 0
  subaccount_id  = var.subaccount_id
  serviceplan_id = data.btp_subaccount_service_plan.my_hana_plan.id
  name           = var.instance_name
  parameters = jsonencode({
    data = local.params_without_mappings
  })
  timeouts = {
    create = "15m"
    update = "15m"
    delete = "5m"
  }
  depends_on = [
    btp_subaccount_subscription.hana_cloud_tools
  ]
}

resource "btp_subaccount_service_instance" "my_sap_hana_cloud_instance_with_mappings" {
  count = var.database_mappings == null ? 0 : 1
  subaccount_id  = var.subaccount_id
  serviceplan_id = data.btp_subaccount_service_plan.my_hana_plan.id
  name           = var.instance_name
  parameters = jsonencode({
    data = local.params_with_mappings
  })
  timeouts = {
    create = "15m"
    update = "15m"
    delete = "5m"
  }
  depends_on = [
    btp_subaccount_subscription.hana_cloud_tools
  ]
}

# look up a service instance by its name and subaccount ID
data "btp_subaccount_service_instance" "my_hana_service" {
  subaccount_id = var.subaccount_id
  name          = var.instance_name
  depends_on = [
    btp_subaccount_service_instance.my_sap_hana_cloud_instance[0]
  ]
}


# create a service binding in a subaccount
resource "btp_subaccount_service_binding" "hc_binding_dbadmin" {
  subaccount_id       = var.subaccount_id
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
  subaccount_id       = var.subaccount_id
  service_instance_id = data.btp_subaccount_service_instance.my_hana_service.id
  name                = "hc-binding"
  depends_on = [
    btp_subaccount_service_instance.my_sap_hana_cloud_instance[0]
  ]
}

# create a parameterized service binding in a subaccount
resource "btp_subaccount_service_binding" "hc_binding_x509" {
  subaccount_id       = var.subaccount_id
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
  subaccount_id = var.subaccount_id
  name          = "lite"
  offering_name = "destination"
  depends_on    = [btp_subaccount_entitlement.destination]
}

# Create/update destination bootstrap service instance
resource "btp_subaccount_service_instance" "dest_bootstrap" {
  subaccount_id  = var.subaccount_id
  serviceplan_id = data.btp_subaccount_service_plan.dest_lite.id
  name           = "dest_bootstrap"
  parameters = jsonencode({

    "init_data": {
        "subaccount": {
            "destinations": [
                  {
                    "Description": "dest-httpbin",
                    "Type": "HTTP",
                    "clientId": "sb-cloneb4e431bc1dcd4f83b5e3843edfee980d!b298674|destination-xsappname!b62",
                    "HTML5.DynamicDestination": "true",
                    "HTML5.Timeout": "60000",
                    "Authentication": "OAuth2ClientCredentials",
                    "Name": "dest-httpbin",
                    "tokenServiceURL": "https://ad8110f5trial.authentication.us10.hana.ondemand.com/oauth/token",
                    "ProxyType": "Internet",
                    "URL": "https://httpbin.org",
                    "tokenServiceURLType": "Dedicated",
                    "clientSecret": "8def3d2d-84a2-4c78-b70f-18e4f4859c00$I7c1DbFl7X6dNkJPLGfVl6O9myHcjA8PQtrjid0D8cU="
                  },
                  {
                    "Description": "SAP Destination Service APIs",
                    "Type": "HTTP",
                    "clientId": "sb-cloneb4e431bc1dcd4f83b5e3843edfee980d!b298674|destination-xsappname!b62",
                    "HTML5.DynamicDestination": "true",
                    "HTML5.Timeout": "60000",
                    "Authentication": "OAuth2ClientCredentials",
                    "Name": "destination-service",
                    "tokenServiceURL": "https://ad8110f5trial.authentication.us10.hana.ondemand.com/oauth/token",
                    "ProxyType": "Internet",
                    "URL": "https://destination-configuration.cfapps.us10.hana.ondemand.com/destination-configuration/v1",
                    "tokenServiceURLType": "Dedicated",
                    "clientSecret": "8def3d2d-84a2-4c78-b70f-18e4f4859c00$I7c1DbFl7X6dNkJPLGfVl6O9myHcjA8PQtrjid0D8cU="
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

# create a service binding in a subaccount
resource "btp_subaccount_service_binding" "dest_binding" {
  subaccount_id       = var.subaccount_id
  service_instance_id = btp_subaccount_service_instance.dest_bootstrap.id
  name                = "dest-binding"

  depends_on = [
    btp_subaccount_service_instance.dest_bootstrap
  ]
}


# create a service binding data source
data "btp_subaccount_service_binding" "dest_binding_data" {
  subaccount_id       = var.subaccount_id
  name                = "dest-binding"
    
  depends_on = [
    btp_subaccount_service_binding.dest_binding
  ]
}