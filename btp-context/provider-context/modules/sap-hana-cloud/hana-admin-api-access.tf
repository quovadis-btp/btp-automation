resource "btp_subaccount_entitlement" "admin_api_access" {
  count         = var.HC_ADMIN_API_ACCESS ? 1 : 0

  subaccount_id = data.btp_subaccount.context.id
  service_name  = var.service_name
  plan_name     = "admin-api-access"
}

data "btp_subaccount_service_plan" "admin_api_access" {
  count         = var.HC_ADMIN_API_ACCESS ? 1 : 0

  subaccount_id = data.btp_subaccount.context.id
  name          = "admin-api-access"
  offering_name = var.service_name
  depends_on = [
    btp_subaccount_entitlement.admin_api_access
  ]
}

#
# https://help.sap.com/docs/hana-cloud/sap-hana-cloud-administration-guide/access-administration-api
#
resource "btp_subaccount_service_instance" "admin_api_access" {
  count         = var.HC_ADMIN_API_ACCESS ? 1 : 0

  subaccount_id  = data.btp_subaccount.context.id
  serviceplan_id = data.btp_subaccount_service_plan.admin_api_access[0].id
  name           = "admin-api-access"

  # https://help.sap.com/docs/btp/sap-business-technology-platform/application-security-descriptor-configuration-syntax#oauth2-configuration-(custom-option)
  #
  parameters = jsonencode({
    "technicalUser": true,
    "oauth2Configuration": {
        "token-validity": 43200,
        "grant-types": [
            "client_credentials"
        ],
        "credential-types": ["binding-secret","x509"]
    }
  })
  timeouts = {
    create = "5m"
    update = "5m"
    delete = "5m"
  }
  depends_on = [
    btp_subaccount_entitlement.admin_api_access
  ]
}


# create an admin_api_access service binding in a subaccount
#
resource "btp_subaccount_service_binding" "admin_api_access_binding" {
  count               = var.HC_ADMIN_API_ACCESS ? 1 : 0

  subaccount_id       = data.btp_subaccount.context.id
  service_instance_id = btp_subaccount_service_instance.admin_api_access[0].id
  name                = "admin-api-access-key"
  depends_on = [
    //btp_subaccount_service_instance.admin_api_access[0]
    btp_subaccount_service_instance.admin_api_access
  ]
}

# create a parameterized admin_api_access service binding in a subaccount
#
resource "btp_subaccount_service_binding" "admin_api_access_binding_x509" {
  count               = var.HC_ADMIN_API_ACCESS ? 1 : 0

  subaccount_id       = data.btp_subaccount.context.id
  service_instance_id = btp_subaccount_service_instance.admin_api_access[0].id
  name                = "admin-api-access-x509"
  parameters = jsonencode({
    credential-type = "x509"
    x509 = {    "key-length": 4096,"validity": 365,"validity-type": "DAYS" }
  })
  depends_on = [
    btp_subaccount_service_instance.admin_api_access[0]
  ]
}

resource "btp_subaccount_service_instance" "dest_admin_api_access" {
  count          = var.HC_ADMIN_API_ACCESS ? 1 : 0
  depends_on     = [btp_subaccount_entitlement.destination, btp_subaccount_service_instance.admin_api_access]

  subaccount_id  = data.btp_subaccount.context.id
  serviceplan_id = data.btp_subaccount_service_plan.dest_lite.id
  name           = "dest_admin_api_access"

  parameters     = jsonencode({

    "init_data": {
        "subaccount": {
            "destinations": [
                  {
                    "Description": "hana-admin-api-access",
                    "Type": "HTTP",
                    "clientId": "${local.admin_api_access-secret.clientid}",
                    "HTML5.DynamicDestination": "true",
                    "HTML5.Timeout": "60000",
                    "Authentication": "OAuth2ClientCredentials",
                    "Name": "hana-admin-api-access",
                    "tokenServiceURL": "${local.admin_api_access-secret.url}/oauth/token",
                    "ProxyType": "Internet",
                    "URL": "${local.admin_api_access-api}",
                    "tokenServiceURLType": "Dedicated",
                    "clientSecret": "${local.admin_api_access-secret.clientsecret}"
                  },
                  {
                    "Description": "httpbin-admin-api-access",
                    "Type": "HTTP",
                    "clientId": "${local.admin_api_access-secret.clientid}",
                    "HTML5.DynamicDestination": "true",
                    "HTML5.Timeout": "60000",
                    "Authentication": "OAuth2ClientCredentials",
                    "Name": "httpbin-admin-api-access",
                    "tokenServiceURL": "${local.admin_api_access-secret.url}/oauth/token",
                    "ProxyType": "Internet",
                    "URL": "https://httpbin.org",
                    "tokenServiceURLType": "Dedicated",
                    "clientSecret": "${local.admin_api_access-secret.clientsecret}"
                  },
                  {
                    "Description": "hana-admin-api-access-x509",
                    "Type": "HTTP",
                    "clientId": "${local.admin_api_access-x509.clientid}",
                    "HTML5.DynamicDestination": "true",
                    "HTML5.Timeout": "60000",
                    "Authentication": "OAuth2ClientCredentials",
                    "Name": "hana-admin-api-access-x509",
                    "tokenServiceURL": "${local.admin_api_access-x509.url}/oauth/token",
                    "ProxyType": "Internet",
                    "URL": "${local.admin_api_access-api}",
                    "tokenServiceURLType": "Dedicated",
                    "tokenService.KeyStoreLocation": "admin-api-access-x509.p12",
                    "tokenService.KeyStorePassword": "Password1"  
                  },
                  {
                    "Description": "httpbin-admin-api-access-x509",
                    "Type": "HTTP",
                    "clientId": "${local.admin_api_access-x509.clientid}",
                    "HTML5.DynamicDestination": "true",
                    "HTML5.Timeout": "60000",
                    "Authentication": "OAuth2ClientCredentials",
                    "Name": "httpbin-admin-api-access-x509",
                    "tokenServiceURL": "${local.admin_api_access-x509.url}/oauth/token",
                    "ProxyType": "Internet",
                    "URL": "https://httpbin.org",
                    "tokenServiceURLType": "Dedicated",
                    "tokenService.KeyStoreLocation": "admin-api-access-x509.p12",
                    "tokenService.KeyStorePassword": "Password1"  
                  }
            ],
           "certificates": [
               "${local.admin_api_access-x509-p12}"
           ],

            "existing_certificates_policy": "update",
            "existing_destinations_policy": "update"           
       }
   }  
  })
}

locals {
  admin_api_access-credentials = one(btp_subaccount_service_binding.admin_api_access_binding[*].credentials)
}

locals {
  admin_api_access-secret = local.admin_api_access-credentials != null ? jsondecode(local.admin_api_access-credentials)["uaa"] : ""
}

locals {
  admin_api_access_x509-credentials = one(btp_subaccount_service_binding.admin_api_access_binding_x509[*].credentials)
}

locals {
  admin_api_access-x509 = local.admin_api_access_x509-credentials != null ? jsondecode(local.admin_api_access_x509-credentials)["uaa"] : ""
}

locals {
  admin_api_access-api = local.admin_api_access_x509-credentials != null ? jsondecode(local.admin_api_access_x509-credentials)["baseurl"] : ""
}

data "external" "openssl_cert_admin_api_access" {
  count          = var.HC_ADMIN_API_ACCESS ? 1 : 0
  depends_on     = [btp_subaccount_service_instance.admin_api_access]

  program = ["bash", "${path.module}/openssl-cert.sh"]

  query = {
    # arbitrary map from strings to strings, passed
    # to the external program as the data query.
    clientid = "${local.admin_api_access-x509.clientid}"
    key = "${local.admin_api_access-x509.key}"    
    certificate = "${local.admin_api_access-x509.certificate}" 
    url = "${local.admin_api_access-x509.certurl}/oauth/token" 
    location = "admin-api-access-x509.p12"
  }
}


locals {
  admin_api_access-x509-p12 = one(data.external.openssl_cert_admin_api_access[*].result)
}
