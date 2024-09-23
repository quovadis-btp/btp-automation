#------------------------------------------------------------------------------------------------------
# BOT OIDC application 
# ------------------------------------------------------------------------------------------------------

resource "btp_subaccount_service_instance" "quovadis-ias-bot" {
  depends_on     = [btp_subaccount_trust_configuration.custom_idp]

  subaccount_id  = data.btp_subaccount.context.id
  name           = "ias-bot"
  serviceplan_id = data.btp_subaccount_service_plan.identity_application.id

  parameters = jsonencode({
        
        "name": "kyma-bot.${data.btp_subaccount.context.id}",
        "display-name": "kyma-bot.${var.BTP_KYMA_NAME}",
        
        "user-access": "public",
        "oauth2-configuration": {
            "grant-types": [
                "authorization_code",
                "authorization_code_pkce_s256",
                "password",
                "refresh_token"
            ],
            "token-policy": {
                "token-validity": 3600,
                "refresh-validity": 15552000,
                "refresh-usage-after-renewal": "off",
                "refresh-parallel": 3,
                "access-token-format": "default"
            },
            "public-client": true,
            "redirect-uris": [
                "https://dashboard.kyma.cloud.sap",
                "https://dashboard.dev.kyma.cloud.sap",
                "https://dashboard.stage.kyma.cloud.sap",
                "http://localhost:8000"
            ]
        },
        "subject-name-identifier": {
            "attribute": "mail",
            "fallback-attribute": "none"
        },
        "default-attributes": null,
        "assertion-attributes": {
            "email": "mail",
            "groups": "companyGroups",
            "first_name": "firstName",
            "last_name": "lastName",
            "login_name": "loginName",
            "mail": "mail",
            "scope": "companyGroups",
            "user_uuid": "userUuid",
            "locale": "language"
        }
  }) 
}


resource "btp_subaccount_service_binding" "ias-bot-binding" {
  depends_on          = [btp_subaccount_service_instance.quovadis-ias-bot]

  subaccount_id       = data.btp_subaccount.context.id
  name                = "ias-bot-binding"
  service_instance_id = btp_subaccount_service_instance.quovadis-ias-bot.id
  parameters = jsonencode({
    credential-type = "NONE"
  })
}

locals {
  bot = nonsensitive(jsondecode(btp_subaccount_service_binding.ias-bot-binding.credentials))
}

/*
resource "local_sensitive_file" "bot" {
  content = jsonencode({
    clientid = local.bot.clientid
    url      = local.bot.url
  })
  filename = "bot.json"
}
*/

# https://developer.hashicorp.com/terraform/language/resources/terraform-data#argument-reference
#

resource "terraform_data" "replacement" {
  input = "${timestamp()}"
}


# https://stackoverflow.com/questions/21297853/how-to-determine-ssl-cert-expiration-date-from-a-pem-encoded-certificate
# https://tldp.org/LDP/abs/html/process-sub.html
/*
      if openssl x509 -checkend 86400 -noout -in <(echo "${local.bot_certificate}" )
      then
        echo "Certificate is good for another day!" 
      else
        echo "Certificate has expired or will do so within 24 hours!" 
        echo "(or is invalid/not found)" 
      fi
      echo "${local.bot_certificate}" | openssl x509 -checkend 86400


*/

resource "terraform_data" "check-cert" {

  triggers_replace = {
    always_run = "${timestamp()}"
  }
  
 provisioner "local-exec" {
   interpreter = ["/bin/bash", "-c"]
   command = <<EOF
   (
      set -e -o pipefail   
      echo "${local.bot_certificate}" | openssl x509 -text -noout
      if openssl x509 -checkend 3600 -noout -in <(echo "${local.bot_certificate}" )
      then
        echo "Certificate is good for at least another hour!" 
      else
        echo "Certificate has expired or will do so within 1 hour!" 
      fi
    ) 
 EOF
 }
}


# https://developer.hashicorp.com/terraform/language/resources/terraform-data#the-terraform_data-managed-resource-type
#
resource "btp_subaccount_service_binding" "ias-bot-binding-cert" {

  depends_on          = [btp_subaccount_service_instance.quovadis-ias-bot]

  subaccount_id       = data.btp_subaccount.context.id
  name                = "ias-bot-binding-cert"
  service_instance_id = btp_subaccount_service_instance.quovadis-ias-bot.id
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
  bot-cert = jsondecode(btp_subaccount_service_binding.ias-bot-binding-cert.credentials)
  bot_certificate = nonsensitive(local.bot-cert.certificate) 
}

output "bot_certificate" {
  value = local.bot_certificate
}

resource "local_sensitive_file" "bot-cert" {
  content = jsonencode({
    clientid    = local.bot-cert.clientid
    certificate = local.bot-cert.certificate
    key         = local.bot-cert.key    
    url         = local.bot-cert.url
  })
  filename = "bot-cert.json"
}

resource "btp_subaccount_service_binding" "ias-bot-binding-secret" {
  depends_on          = [btp_subaccount_service_instance.quovadis-ias-bot]

  subaccount_id       = data.btp_subaccount.context.id
  name                = "ias-bot-binding-secret"
  service_instance_id = btp_subaccount_service_instance.quovadis-ias-bot.id
  parameters = jsonencode({
    credential-type = "SECRET"
  })
}

locals {
  bot-secret = jsondecode(btp_subaccount_service_binding.ias-bot-binding-secret.credentials)
}

resource "local_sensitive_file" "bot-secret" {
  content = jsonencode({
    clientid = local.bot-secret.clientid
    url      = local.bot-secret.url
  })
  filename = "bot-secret.json"
}


/*
.PHONY: bootstrap-kymaruntime-bot
bootstrap-kymaruntime-bot: ## bootstrap kyma openidconnect resource
  btp get services/binding --name ias-bot-binding | jq '.credentials | { clientid,  url }' > bot.json
  jq 'input as  $$idp  | .metadata |= . + {name: $$idp.clientid} | .spec |= . + { clientID: $$idp.clientid , issuerURL: $$idp.url, usernameClaim: "sub", usernamePrefix: "bot-identity:" , groupsClaim: "", groupsPrefix: "" }' kyma-bot-template.json bot.json
  kubectl create ns $(NAMESPACE) --kubeconfig $(KUBECONFIG) --dry-run=client -o yaml | kubectl apply --kubeconfig $(KUBECONFIG) -f -
  kubectl label namespace $(NAMESPACE) istio-injection=enabled --kubeconfig $(KUBECONFIG)
  jq 'input as  $$idp  | .metadata |= . + {name: $$idp.clientid} | .spec |= . + { clientID: $$idp.clientid , issuerURL: $$idp.url, usernameClaim: "email", usernamePrefix: "bot-identity:" , groupsClaim: "", groupsPrefix: "" }' kyma-bot-template.json bot.json \
  | kubectl apply --kubeconfig $(KUBECONFIG) -n $(NAMESPACE) -f - 


    echo $OpenIDConnect | kubectl apply --kubeconfig $KUBECONFIG -n $NAMESPACE -f - 
    jq -r '.' <<< "$OpenIDConnect"  > bootstrap-kymaruntime-bot.json

*/

/* debug only
locals {
  OpenIDConnect = jsonencode({

        "apiVersion": "authentication.gardener.cloud/v1alpha1",
        "kind": "OpenIDConnect",
        "metadata": {
            "name": "${local.bot-cert.clientid}"
        },
        "spec": {
            "issuerURL": "${local.bot-cert.url}",
            "clientID": "${local.bot-cert.clientid}",
            "usernameClaim": "sub",
            "usernamePrefix": "bot-identity:",
            "groupsClaim": "",
            "groupsPrefix": ""
        }
  })
}

resource "local_sensitive_file" "OpenIDConnect" {
  content         = local.OpenIDConnect
  file_permission = "0600"
  filename        = "OpenIDConnect.json"
}

# https://discuss.hashicorp.com/t/is-there-any-way-to-inspect-module-variables-and-outputs/25702
#
output "OpenIDConnect" {
  value = nonsensitive(local.OpenIDConnect)
}
*/

# https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax#the-self-object
# https://developer.hashicorp.com/terraform/language/resources/terraform-data
# https://developer.hashicorp.com/terraform/language/functions/nonsensitive
#
# bootstrap kyma openidconnect resource
#
resource "terraform_data" "bootstrap-kymaruntime-bot" {
  depends_on = [terraform_data.kubectl_getnodes]

/*
  triggers_replace = {
    always_run = "${timestamp()}"
  }
*/

  triggers_replace = [
        terraform_data.kubectl_getnodes
  ]

  # the input becomes a definition of an OpenIDConnect provider as a non-sensitive json encoded string 
  #
  input = nonsensitive(
    jsonencode({
        "apiVersion": "authentication.gardener.cloud/v1alpha1",
        "kind": "OpenIDConnect",
        "metadata": {
            "name": "${local.bot-cert.clientid}"
        },
        "spec": {
            "issuerURL": "${local.bot-cert.url}",
            "clientID": "${local.bot-cert.clientid}",
            "usernameClaim": "sub",
            "usernamePrefix": "bot-identity:",
            "groupsClaim": "",
            "groupsPrefix": ""
        }
    })
  )

 # https://discuss.hashicorp.com/t/resource-attribute-json-quotes-getting-stripped/45752/4
 # https://stackoverflow.com/questions/75255995/how-to-echo-a-jq-json-with-double-quotes-escaped-with-backslash
 #
 provisioner "local-exec" {
   interpreter = ["/bin/bash", "-c"]
   command = <<EOF
     (
    KUBECONFIG=kubeconfig-headless.yaml
    NAMESPACE=quovadis-btp
    set -e -o pipefail ;\
    
    ./kubectl wait --for condition=established crd openidconnects.authentication.gardener.cloud --timeout=180s --kubeconfig $KUBECONFIG
    crd=$(./kubectl get crd openidconnects.authentication.gardener.cloud --kubeconfig $KUBECONFIG -ojsonpath='{.metadata.name}' --ignore-not-found)
    if [ "$crd" = "openidconnects.authentication.gardener.cloud" ]
    then
      OpenIDConnect='${self.input}'
      echo $(jq -r '.' <<< $OpenIDConnect)
      echo $OpenIDConnect

      echo | ./kubectl get nodes --kubeconfig $KUBECONFIG
      ./kubectl create ns $NAMESPACE --kubeconfig $KUBECONFIG --dry-run=client -o yaml | ./kubectl apply --kubeconfig $KUBECONFIG -f -
      ./kubectl label namespace $NAMESPACE istio-injection=enabled --kubeconfig $KUBECONFIG

      # a debug line until the OpenIDConnect CRD is installed via the oidc shoot extension
      #
      echo $(jq -r '.' <<< $OpenIDConnect ) >  bootstrap-kymaruntime-bot.json
      echo $OpenIDConnect | ./kubectl apply --kubeconfig $KUBECONFIG -n $NAMESPACE -f - 
    else
      echo $crd
    fi

     )
   EOF
 }
}


# https://help.sap.com/docs/btp/sap-business-technology-platform/configure-custom-identity-provider-for-kyma
# 
locals {

  # The email adresses must be recognised by https://kyma.accounts.ondemand.com. (be part of SAP ID at accounts.sap.com)

  OpenIDConnect_PROD = jsonencode({

        "apiVersion": "authentication.gardener.cloud/v1alpha1",
        "kind": "OpenIDConnect",
        "metadata": {
            "name": "12b13a26-d993-4d0c-aa08-5f5852bbdff6"
        },
        "spec": {
            "issuerURL": "https://kyma.accounts.ondemand.com",
            "clientID": "12b13a26-d993-4d0c-aa08-5f5852bbdff6",
            "usernameClaim": "sub",
            "usernamePrefix": "-",
            "groupsClaim": "groups",
            "groupsPrefix": ""
        }
    })

  # The email adresses must be recognised by https://kyma.accounts400.ondemand.com. (be part of SAP ID at accounts400.sap.com)

  OpenIDConnect_STAGE = jsonencode({

        "apiVersion": "authentication.gardener.cloud/v1alpha1",
        "kind": "OpenIDConnect",
        "metadata": {
            "name": "e69c0ad6-c283-4baf-9ad7-3714decef49d"
        },
        "spec": {
            "issuerURL": "https://kyma.accounts400.ondemand.com",
            "clientID": "e69c0ad6-c283-4baf-9ad7-3714decef49d",
            "usernameClaim": "sub",
            "usernamePrefix": "-",
            "groupsClaim": "groups",
            "groupsPrefix": ""
        }
  })

}

# https://stackoverflow.com/questions/69996346/how-to-make-terraform-provider-dependent-on-a-resource-being-created
# https://stackoverflow.com/questions/78906551/terraform-kubernetes-provider-depending-on-azurerm-kubernetes-cluster-resource
# https://stackoverflow.com/questions/73321432/terraform-kubectl-provider-error-failed-to-create-kubernetes-rest-client-for-re
# https://support.hashicorp.com/hc/en-us/articles/4408936406803-Kubernetes-Provider-block-fails-with-connect-connection-refused
#
resource "kubectl_manifest" "OpenIDConnect_PROD" {
//    depends_on = [ module.runtime_context.kubeconfig_prod_exec ]
    depends_on = [ terraform_data.bootstrap-kymaruntime-bot ]

    yaml_body  = yamlencode(jsondecode(local.OpenIDConnect_PROD))
    server_side_apply = true
    apply_only = true
}

resource "kubectl_manifest" "OpenIDConnect_STAGE" {
//    depends_on = [ module.runtime_context.kubeconfig_prod_exec ]
    depends_on = [ terraform_data.bootstrap-kymaruntime-bot, output.kubeconfig_prod_exec ]

    yaml_body  = yamlencode(jsondecode(local.OpenIDConnect_STAGE))
    server_side_apply = true
    apply_only = true    
}

data "http" "token-bot" {
  url = "${local.idp.url}/oauth2/token"
  method = "POST"
  request_headers = {
    Content-Type  = "application/x-www-form-urlencoded"
  }  
  request_body = "grant_type=password&username=${var.BTP_BOT_USER}&password=${var.BTP_BOT_PASSWORD}&client_id=${local.bot.clientid}&scope=groups,email"
}

resource "local_sensitive_file" "headless-token-bot" {
  content  = data.http.token-bot.response_body
  filename = "headless-token-bot.json"
}


data "http" "token-secret-bot" {
  url = "${local.idp-secret.url}/oauth2/token"
  method = "POST"
  request_headers = {
    Content-Type  = "application/x-www-form-urlencoded"
  }  
  request_body = "grant_type=password&username=${var.BTP_BOT_USER}&password=${var.BTP_BOT_PASSWORD}&client_id=${local.bot-secret.clientid}&client_secret=${local.bot-secret.clientsecret}&scope=groups,email"
}

resource "local_sensitive_file" "headless-token-bot-secret" {
  content  = data.http.token-secret-bot.response_body
  filename = "headless-token-bot-secret.json"
}

# https://github.com/hashicorp/terraform-provider-http/blob/main/docs/data-sources/http.md
# https://medium.com/@haroldfinch01/how-to-create-an-ssh-key-in-terraform-0c5cfd3d46dd
# https://registry.terraform.io/providers/salrashid123/http-full/latest/docs/data-sources/http
# https://github.com/salrashid123/terraform-provider-http-full

data "http" "token-cert-bot" {
  provider = http-full

  url = "${local.bot-cert.url}/oauth2/token"
  #ca_cert_pem = 
  method = "POST"
  request_headers = {
    Content-Type  = "application/x-www-form-urlencoded"
  }
  client_crt = local.bot-cert.certificate
  client_key = local.bot-cert.key

  request_body = "grant_type=password&username=${var.BTP_BOT_USER}&password=${var.BTP_BOT_PASSWORD}&client_id=${local.bot-cert.clientid}&scope=groups,email"

}

resource "local_sensitive_file" "headless-token-bot-cert" {
  content  = data.http.token-cert-bot.response_body
  filename = "headless-token-bot-cert.json"
}



# https://gist.github.com/ptesny/14f49f49e0fbe2a3143700ce707ee76b#72-sap-cloud-identity-services-as-a-custom-oidc-provider
#
locals {  
    kubeconfig_bot_exec = jsonencode({
        "apiVersion": "client.authentication.k8s.io/v1",
        "interactiveMode": "Never",
        "command": "bash",
        "args": [
            "-c",
            "set -e -o pipefail\n\nIDTOKEN=$(curl -X POST  \"${local.bot.url}/oauth2/token\" \\\n-H 'Content-Type: application/x-www-form-urlencoded' \\\n-d 'grant_type=password' \\\n-d 'username='\"${var.BTP_BOT_USER}\" \\\n-d 'password='\"${var.BTP_BOT_PASSWORD}\" \\\n-d 'client_id='\"${local.bot.clientid}\" \\\n-d 'scope=groups, email' \\\n| jq -r '. | .id_token ' ) \n\n# Print decoded token information for debugging purposes\necho ::debug:: JWT content: \"$(echo \"$IDTOKEN\" | jq -c -R 'split(\".\") | .[1] | @base64d | fromjson')\" >&2\n\nEXP_TS=$(echo $IDTOKEN | jq -R 'split(\".\") | .[1] | @base64d | fromjson | .exp')\n# EXP_DATE=$(date -d @$EXP_TS --iso-8601=seconds)          \ncat << EOF\n{\n  \"apiVersion\": \"client.authentication.k8s.io/v1\",\n  \"kind\": \"ExecCredential\",\n  \"status\": {\n    \"token\": \"$IDTOKEN\"\n  }\n}\nEOF\n"
        ]
    })         

    kubeconfig_prod_exec = jsonencode({
        "apiVersion": "client.authentication.k8s.io/v1",
        "interactiveMode": "Never",
        "command": "bash",
        "args": [
            "-c",
            "set -e -o pipefail\n\nIDTOKEN=$(curl -X POST  \"https://kyma.accounts.ondemand.com/oauth2/token\" \\\n-H 'Content-Type: application/x-www-form-urlencoded' \\\n-d 'grant_type=password' \\\n-d 'username='\"${var.BTP_BOT_USER}\" \\\n-d 'password='\"${var.BTP_BOT_PASSWORD}\" \\\n-d 'client_id='\"12b13a26-d993-4d0c-aa08-5f5852bbdff6\" \\\n-d 'scope=groups, email' \\\n| jq -r '. | .id_token ' ) \n\n# Print decoded token information for debugging purposes\necho ::debug:: JWT content: \"$(echo \"$IDTOKEN\" | jq -c -R 'split(\".\") | .[1] | @base64d | fromjson')\" >&2\n\nEXP_TS=$(echo $IDTOKEN | jq -R 'split(\".\") | .[1] | @base64d | fromjson | .exp')\n# EXP_DATE=$(date -d @$EXP_TS --iso-8601=seconds)          \ncat << EOF\n{\n  \"apiVersion\": \"client.authentication.k8s.io/v1\",\n  \"kind\": \"ExecCredential\",\n  \"status\": {\n    \"token\": \"$IDTOKEN\"\n  }\n}\nEOF\n"
        ]
    })         


}

data "jq_query" "kubeconfig_bot_exec" {
   depends_on = [data.http.kubeconfig]

   data = jsonencode(yamldecode(data.http.kubeconfig.response_body))
   query = "del(.users[] | .user | .exec) | .users[] |= . + { user: { exec: ${local.kubeconfig_bot_exec} } }"
}

output "kubeconfig_bot_exec" {
#  value = jsondecode(data.jq_query.kubeconfig_bot_exec.result)
  value = yamlencode(jsondecode(data.jq_query.kubeconfig_bot_exec.result))

  # https://stackoverflow.com/questions/58275233/terraform-depends-on-with-modules
  #
  depends_on = [ terraform_data.bootstrap-kymaruntime-bot ]
}

data "jq_query" "kubeconfig_prod_exec" {
   depends_on = [data.http.kubeconfig]

   data = jsonencode(yamldecode(data.http.kubeconfig.response_body))
   query = "del(.users[] | .user | .exec) | .users[] |= . + { user: { exec: ${local.kubeconfig_prod_exec} } }"
}

output "kubeconfig_prod_exec" {
#  value = jsondecode(data.jq_query.kubeconfig_prod_exec.result)
  value = yamlencode(jsondecode(data.jq_query.kubeconfig_prod_exec.result))

  # https://stackoverflow.com/questions/58275233/terraform-depends-on-with-modules
  #
  depends_on = [ terraform_data.bootstrap-kymaruntime-bot ]
}

/* 
resource "local_sensitive_file" "kubeconfig_bot_exec" {
  depends_on = [data.jq_query.kubeconfig_bot_exec]

  content  = yamlencode(jsondecode(data.jq_query.kubeconfig_bot_exec.result) )
  filename = "kubeconfig_bot_exec.yaml"
}

resource "local_sensitive_file" "kubeconfig_bot_exec_json" {
  depends_on = [data.jq_query.kubeconfig_bot_exec]

  content  = data.jq_query.kubeconfig_bot_exec.result
  filename = "kubeconfig_bot_exec.json"
}
*/
 