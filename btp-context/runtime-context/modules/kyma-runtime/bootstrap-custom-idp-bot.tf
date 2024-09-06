#------------------------------------------------------------------------------------------------------
# BOT OIDC application 
# ------------------------------------------------------------------------------------------------------

resource "btp_subaccount_service_instance" "quovadis-ias-bot" {
  depends_on     = [btp_subaccount_trust_configuration.custom_idp]

  subaccount_id  = data.btp_subaccount.context.id
  name           = "ias-bot"
  serviceplan_id = data.btp_subaccount_service_plan.identity_application.id

  parameters = jsonencode({
        
        "name": "kyma-bot-${data.btp_subaccount.context.id}",
        "display-name": "kyma-bot",
        
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
  bot = jsondecode(btp_subaccount_service_binding.ias-bot-binding.credentials)
}

resource "local_sensitive_file" "bot" {
  content = jsonencode({
    clientid = local.bot.clientid
    url      = local.bot.url
  })
  filename = "bot.json"
}

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
    
    OpenIDConnect='${self.input}'
    echo $(jq -r '.' <<< $OpenIDConnect)
    echo $OpenIDConnect

    echo | kubectl get nodes --kubeconfig $KUBECONFIG
    kubectl create ns $NAMESPACE --kubeconfig $KUBECONFIG --dry-run=client -o yaml | kubectl apply --kubeconfig $KUBECONFIG -f -
    kubectl label namespace $NAMESPACE istio-injection=enabled --kubeconfig $KUBECONFIG

    # a debug line until the OpenIDConnect CRD is installed via the oidc shoot extension
    #
    echo $(jq -r '.' <<< $OpenIDConnect ) >  bootstrap-kymaruntime-bot.json
    #echo $OpenIDConnect | kubectl apply --kubeconfig $KUBECONFIG -n $NAMESPACE -f - 

     )
   EOF
 }
}
