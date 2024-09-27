resource "btp_subaccount_entitlement" "admin_api_access" {
  count         = local.admin_api_access == {} ? 0 : 1

  subaccount_id = data.btp_subaccount.context.id
  service_name  = var.service_name
  plan_name     = "admin-api-access"
}

data "btp_subaccount_service_plan" "admin_api_access" {
  count         = local.admin_api_access == {} ? 0 : 1

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
  count         = local.admin_api_access == {} ? 0 : 1

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
  count               = local.admin_api_access == {} ? 0 : 1

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
  count               = local.admin_api_access == {} ? 0 : 1

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
  count          = local.admin_api_access == {} ? 0 : 1
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
                    "URL": "https://${local.admin_api_access-api}",
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
                    "tokenServiceURL": "${local.admin_api_access-x509.certurl}/oauth/token",
                    "ProxyType": "Internet",
                    "URL": "https://${local.admin_api_access-api}",
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
                    "tokenServiceURL": "${local.admin_api_access-x509.certurl}/oauth/token",
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
  admin_api_access-secret = local.admin_api_access-credentials != null ? jsondecode(local.admin_api_access-credentials)["uaa"] : {clientid: "", clientsecret: "", url: "",}
}

locals {
  admin_api_access_x509-credentials = one(btp_subaccount_service_binding.admin_api_access_binding_x509[*].credentials)
}

locals {
  admin_api_access-x509 = local.admin_api_access_x509-credentials != null ? jsondecode(local.admin_api_access_x509-credentials)["uaa"] : {clientid: "", url: "" }
}


locals {
  admin_api_access-api = local.admin_api_access_x509-credentials != null ? jsondecode(local.admin_api_access_x509-credentials)["baseurl"] : ""
}

data "external" "openssl_cert_admin_api_access" {
  count          = local.admin_api_access == {} ? 0 : 1
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

output "hc-inventory" {
  value       = local.admin_api_access_x509-credentials == null ? "${local.sap_approuter_dynamic_dest}/hc-services/inventory/v2/serviceInstances/${data.btp_subaccount_service_instance.my_hana_service.id}/instanceMappings" : "${local.sap_approuter_dynamic_dest}/hana-admin-api-access/inventory/v2/serviceInstances/${data.btp_subaccount_service_instance.my_hana_service.id}/instanceMappings"
  
  description = "SAP HANA Cloud Management APIs"
}


data "http" "token-cert-admin_api_access" {
  count          = local.admin_api_access == {} ? 0 : 1
  depends_on     = [btp_subaccount_service_instance.admin_api_access]

  provider = http-full

  url = "${local.admin_api_access-x509.certurl}/oauth/token" 

  method = "POST"
  request_headers = {
    Content-Type  = "application/x-www-form-urlencoded"
  }
  client_crt = local.admin_api_access-x509.certificate
  client_key = local.admin_api_access-x509.key

  request_body = "grant_type=client_credentials&client_id=${local.admin_api_access-x509.clientid}"

}

locals {
  token-cert-admin_api_access = one(data.http.token-cert-admin_api_access[*].response_body)
  access_token = local.token-cert-admin_api_access != null ? jsondecode(local.token-cert-admin_api_access).access_token : ""
}


output "token-cert-admin_api_access" {
  value = nonsensitive(local.token-cert-admin_api_access)
}

data "http" "get_instanceMappings" {

  count          = local.admin_api_access == {} ? 0 : 1
  depends_on     = [ data.http.token-cert-admin_api_access ]

  provider = http-full

  url = "https://${local.admin_api_access-api}/inventory/v2/serviceInstances/${data.btp_subaccount_service_instance.my_hana_service.id}/instanceMappings" 

  method = "GET"
  request_headers = {
    Content-Type = "application/json",
    Authorization = "Bearer ${local.access_token}"
  }

  lifecycle {
    postcondition {
      condition     = contains([200], self.status_code)
      error_message = self.response_body
    }
  }
}

output "get_instanceMappings" {
  value = nonsensitive(one(data.http.get_instanceMappings[*].response_body))
}


# https://developer.hashicorp.com/terraform/language/state/remote-state-data#the-terraform_remote_state-data-source
# https://spacelift.io/blog/terraform-data-sources-how-they-are-utilised
# https://ourcloudschool.medium.com/read-terraform-provisioned-resources-with-terraform-remote-state-datasource-ab9cf882ab63
# https://spacelift.io/blog/terraform-remote-state
# https://fabianlee.org/2023/08/06/terraform-terraform_remote_state-to-pass-values-to-other-configurations/
#
data "terraform_remote_state" "runtime_context" {
  count   = var.runtime_context_backend != "tfe" ? 1 : 0

  backend = var.runtime_context_backend 
  config  = var.runtime_context_backend == "kubernetes" ? var.runtime_context_kubernetes_backend_config : var.runtime_context_local_backend_config 
}

# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/outputs?ajs_aid=3951d9c3-6a9a-4a4d-826b-b5a7fc7daf9f&product_intent=terraform
#
data "tfe_outputs" "runtime_context" {
  count        = var.runtime_context_backend == "tfe" ? 1 : 0

  organization = var.runtime_context_organization
  workspace    = var.runtime_context_workspace
}

// this provider context can be null
locals {
  remote_backend = one(data.terraform_remote_state.runtime_context[*].outputs.cluster_id)
  tfe_backend    = one(data.tfe_outputs.runtime_context[*].values.cluster_id)

  cluster_id = nonsensitive(local.remote_backend != null ? jsonencode(local.remote_backend) : jsonencode(local.tfe_backend))

}


data "http" "add_instanceMappings" {

  count          = local.admin_api_access == {} ? 0 : 1
  depends_on     = [btp_subaccount_service_instance.admin_api_access, data.http.token-cert-admin_api_access]

  provider = http-full

  url = "https://${local.admin_api_access-api}/inventory/v2/serviceInstances/${data.btp_subaccount_service_instance.my_hana_service.id}/instanceMappings" 

  method = "POST"
  request_headers = {
    Content-Type = "application/json",
    Authorization = "Bearer ${local.access_token}"
  }
  request_body = jsonencode({
        "platform": "kubernetes",
        "primaryID": "${local.cluster_id}"
      })

  lifecycle {
    postcondition {
      condition     = contains([200, 201], self.status_code)
      error_message = self.response_body
    }
  }
}

output "add_instanceMappings" {
  value = nonsensitive(one(data.http.add_instanceMappings[*].response_body))
}

