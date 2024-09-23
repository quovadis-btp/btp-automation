
# ------------------------------------------------------------------------------------------------------
# OIDC application 
# ------------------------------------------------------------------------------------------------------

resource "btp_subaccount_entitlement" "identity_application" {
  subaccount_id = data.btp_subaccount.context.id
  service_name  = "identity"
  plan_name     = "application"
}

data "btp_subaccount_service_plan" "identity_application" {
  depends_on     = [btp_subaccount_entitlement.identity_application]

  subaccount_id = data.btp_subaccount.context.id
  offering_name = "identity"
  name          = "application"
}

resource "btp_subaccount_service_instance" "identity_application" {
  depends_on     = [btp_subaccount_trust_configuration.custom_idp]

  subaccount_id  = data.btp_subaccount.context.id
  name           = "ias-local"
  serviceplan_id = data.btp_subaccount_service_plan.identity_application.id

  parameters = jsonencode({
    user-access = "public"
    oauth2-configuration = {
      grant-types = [
        "authorization_code",
        "authorization_code_pkce_s256",
        "password",
        "refresh_token"
      ],
      token-policy = {
        token-validity              = 3600,
        refresh-validity            = 15552000,
        refresh-usage-after-renewal = "off",
        refresh-parallel            = 3,
        access-token-format         = "default"
      },
      public-client = true,
      redirect-uris = [
        "https://dashboard.kyma.cloud.sap",
        "https://dashboard.dev.kyma.cloud.sap",
        "https://dashboard.stage.kyma.cloud.sap",
        "http://localhost:8000"
      ]
    },
    subject-name-identifier = {
      attribute          = "mail",
      fallback-attribute = "none"
    },
    default-attributes = null,
    assertion-attributes = {
      email      = "mail",
      groups     = "companyGroups",
      first_name = "firstName",
      last_name  = "lastName",
      login_name = "loginName",
      mail       = "mail",
      scope      = "companyGroups",
      user_uuid  = "userUuid",
      locale     = "language"
    },
    name         = "${var.BTP_KYMA_NAME}-${var.BTP_KYMA_PLAN}-${data.btp_subaccount.context.id}",
    display-name = "${var.BTP_KYMA_NAME}-${var.BTP_KYMA_PLAN}"
  })
}


resource "btp_subaccount_service_binding" "ias-local-binding" {
  depends_on          = [btp_subaccount_service_instance.identity_application]

  subaccount_id       = data.btp_subaccount.context.id
  name                = "ias-local-binding"
  service_instance_id = btp_subaccount_service_instance.identity_application.id
  parameters = jsonencode({
    credential-type = "NONE"
  })
}

locals {
  idp = nonsensitive(jsondecode(btp_subaccount_service_binding.ias-local-binding.credentials))
}

output "idp" {
  value = local.idp
}

/*
resource "local_sensitive_file" "idp" {
  content = jsonencode({
    clientid = local.idp.clientid
    url      = local.idp.url
  })
  filename = "idp.json"
}
*/

resource "btp_subaccount_service_binding" "ias-local-binding-cert" {
  depends_on          = [btp_subaccount_service_instance.identity_application]

  subaccount_id       = data.btp_subaccount.context.id
  name                = "ias-local-binding-cert"
  service_instance_id = btp_subaccount_service_instance.identity_application.id
  parameters = jsonencode({
    credential-type = "X509_GENERATED"
    key-length      = 4096
    validity        = 1
    validity-type   = "DAYS"
    app-identifier  = "kymaruntime"
  })
  lifecycle {
    replace_triggered_by = [
      terraform_data.replacement
    ]
  }
}

locals {
  idp-cert = jsondecode(btp_subaccount_service_binding.ias-local-binding-cert.credentials)
}

resource "local_sensitive_file" "idp-cert" {
  content = jsonencode({
    clientid    = local.idp-cert.clientid
    certificate = local.idp-cert.certificate
    key         = local.idp-cert.key
    url         = local.idp-cert.url
  })
  filename = "idp-cert.json"
}

resource "btp_subaccount_service_binding" "ias-local-binding-secret" {
  depends_on          = [btp_subaccount_service_instance.identity_application]

  subaccount_id       = data.btp_subaccount.context.id
  name                = "ias-local-binding-secret"
  service_instance_id = btp_subaccount_service_instance.identity_application.id
  parameters = jsonencode({
    credential-type = "SECRET"
  })
}

locals {
  idp-secret = jsondecode(btp_subaccount_service_binding.ias-local-binding-secret.credentials)
}

resource "local_sensitive_file" "idp-secret" {
  content = jsonencode({
    clientid = local.idp-secret.clientid
    clientsecret = local.idp-secret.clientsecret
    url      = local.idp-secret.url
  })
  filename = "idp-secret.json"
}

output "id_token" {
  value = jsondecode(data.http.token.response_body).id_token
}


# https://stackoverflow.com/questions/78625440/terraform-http-provider-handling-lists-in-request-body
# https://github.com/hashicorp/terraform-provider-http/issues/304
# https://spacelift.io/blog/terraform-jsonencode#example-5-using-jsonencode-with-the-for-loop
# https://registry.terraform.io/browse/providers?tier=official
# https://spacelift.io/blog/terraform-yaml#what-is-the-yamldecode-function-in-terraform
#
data "http" "token" {
  url = "${local.idp.url}/oauth2/token"
  method = "POST"
  request_headers = {
    #Authorization = "Basic ${base64encode( "${var.BTP_BOT_USER}:${var.BTP_BOT_PASSWORD}" ) }"
    Content-Type  = "application/x-www-form-urlencoded"
  }  
  request_body = "grant_type=password&username=${var.BTP_BOT_USER}&password=${var.BTP_BOT_PASSWORD}&client_id=${local.idp.clientid}&scope=groups,email"
}

resource "local_sensitive_file" "headless-token" {
  content  = data.http.token.response_body
  #filename = ".${data.btp_subaccount.context.id}-${var.BTP_KYMA_NAME}.token"
  filename = "headless-token.json"
}


data "http" "token-secret" {
  url = "${local.idp-secret.url}/oauth2/token"
  method = "POST"
  request_headers = {
    Content-Type  = "application/x-www-form-urlencoded"
  }  
  request_body = "grant_type=password&username=${var.BTP_BOT_USER}&password=${var.BTP_BOT_PASSWORD}&client_id=${local.idp-secret.clientid}&client_secret=${local.idp-secret.clientsecret}&scope=groups,email"
}

resource "local_sensitive_file" "headless-token-secret" {
  content  = data.http.token-secret.response_body
  filename = "headless-token-secret.json"
}

# https://github.com/hashicorp/terraform-provider-http/blob/main/docs/data-sources/http.md
# https://medium.com/@haroldfinch01/how-to-create-an-ssh-key-in-terraform-0c5cfd3d46dd
# https://registry.terraform.io/providers/salrashid123/http-full/latest/docs/data-sources/http
# https://github.com/salrashid123/terraform-provider-http-full

data "http" "token-cert" {
  provider = http-full

  url = "${local.idp-cert.url}/oauth2/token"
  #ca_cert_pem = 
  method = "POST"
  request_headers = {
    Content-Type  = "application/x-www-form-urlencoded"
  }
  client_crt = local.idp-cert.certificate
  client_key = local.idp-cert.key

  request_body = "grant_type=password&username=${var.BTP_BOT_USER}&password=${var.BTP_BOT_PASSWORD}&client_id=${local.idp-cert.clientid}&scope=groups,email"

}

resource "local_sensitive_file" "headless-token-cert" {
  content  = data.http.token-cert.response_body
  filename = "headless-token-cert.json"
}

# https://gist.github.com/ptesny/14f49f49e0fbe2a3143700ce707ee76b#72-sap-cloud-identity-services-as-a-custom-oidc-provider
#
locals {  
    kubeconfig_exec = jsonencode({
        "apiVersion": "client.authentication.k8s.io/v1",
        "interactiveMode": "Never",
        "command": "bash",
        "args": [
            "-c",
            "set -e -o pipefail\n\nIDTOKEN=$(curl -X POST  \"${local.idp.url}/oauth2/token\" \\\n-H 'Content-Type: application/x-www-form-urlencoded' \\\n-d 'grant_type=password' \\\n-d 'username='\"${var.BTP_BOT_USER}\" \\\n-d 'password='\"${var.BTP_BOT_PASSWORD}\" \\\n-d 'client_id='\"${local.idp.clientid}\" \\\n-d 'scope=groups, email' \\\n| jq -r '. | .id_token ' ) \n\n# Print decoded token information for debugging purposes\necho ::debug:: JWT content: \"$(echo \"$IDTOKEN\" | jq -c -R 'split(\".\") | .[1] | @base64d | fromjson')\" >&2\n\nEXP_TS=$(echo $IDTOKEN | jq -R 'split(\".\") | .[1] | @base64d | fromjson | .exp')\n# EXP_DATE=$(date -d @$EXP_TS --iso-8601=seconds)          \ncat << EOF\n{\n  \"apiVersion\": \"client.authentication.k8s.io/v1\",\n  \"kind\": \"ExecCredential\",\n  \"status\": {\n    \"token\": \"$IDTOKEN\"\n  }\n}\nEOF\n"
        ]
    })         
}

data "jq_query" "kubeconfig_exec" {
   depends_on = [data.http.kubeconfig]

   data = jsonencode(yamldecode(data.http.kubeconfig.response_body))
   query = "del(.users[] | .user | .exec) | .users[] |= . + { user: { exec: ${local.kubeconfig_exec} } }"
}

output "kubeconfig_exec" {
#  value = jsondecode(data.jq_query.kubeconfig_exec.result)
  value = yamlencode(jsondecode(data.jq_query.kubeconfig_exec.result))
}

/* 
resource "local_sensitive_file" "kubeconfig_exec" {
   depends_on = [data.jq_query.kubeconfig_exec]

  content  = yamlencode(jsondecode(data.jq_query.kubeconfig_exec.result) )
  filename = "kubeconfig_exec.yaml"
}

resource "local_sensitive_file" "kubeconfig_exec_json" {
   depends_on = [data.jq_query.kubeconfig_exec]

  content  = data.jq_query.kubeconfig_exec.result
  filename = "kubeconfig_exec.json"
}
*/

