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

/*
resource "local_sensitive_file" "bot-cert" {
  content = jsonencode({
    clientid    = local.bot-cert.clientid
    certificate = local.bot-cert.certificate
    key         = local.bot-cert.key    
    url         = local.bot-cert.url
  })
  filename = "bot-cert.json"
}
*/

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

/*
resource "local_sensitive_file" "bot-secret" {
  content = jsonencode({
    clientid = local.bot-secret.clientid
    url      = local.bot-secret.url
  })
  filename = "bot-secret.json"
}
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


# https://help.sap.com/docs/btp/sap-business-technology-platform/configure-custom-identity-provider-for-kyma
# 
locals {

  # The email adresses must be recognised by https://kyma.accounts.ondemand.com. (be part of SAP ID at accounts.sap.com)

  OpenIDConnect_PROD = jsonencode({

        "apiVersion": "authentication.gardener.cloud/v1alpha1",
        "kind": "OpenIDConnect",
        "metadata": {
            "name": "kyma-oidc"
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

  # The email adresses must be recognised by https://kymatest.accounts400.ondemand.com. (be part of SAP ID at accounts400.sap.com)

  OpenIDConnect_STAGE = jsonencode({

        "apiVersion": "authentication.gardener.cloud/v1alpha1",
        "kind": "OpenIDConnect",
        "metadata": {
            "name": "kymatest-oidc"
        },
        "spec": {
            "issuerURL": "https://kymatest.accounts400.ondemand.com",
            "clientID": "e69c0ad6-c283-4baf-9ad7-3714decef49d",
            "usernameClaim": "sub",
            "usernamePrefix": "-",
            "groupsClaim": "groups",
            "groupsPrefix": ""
        }
  })

  # https://token.actions.githubusercontent.com/.well-known/openid-configuration
  # https://token.actions.githubusercontent.com/.well-known/jwks
  # https://mahendranp.medium.com/configure-github-openid-connect-oidc-provider-in-aws-b7af1bca97dd
  # https://github.com/google-github-actions/auth
  #
  # https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect#overview-of-openid-connect
  # 
  # https://github.com/gardener/oidc-webhook-authenticator/blob/master/README.md
  # https://github.com/gardener/gardener-extension-shoot-oidc-service/blob/master/docs/usage/openidconnects.md
  # https://community.sap.com/t5/open-source-blogs/using-github-actions-openid-connect-in-kubernetes/ba-p/13542513
  #
  # user name format: actions-oidc:repo:myOrg/myRepo:ref:refs/heads/main
  #
  # https://github.com/pPrecel/gardener-oidc-extension-poc/blob/main/.github/workflows/setup-serverless-on-gardener.yaml
  # https://github.com/kyma-project/cli/issues/2093
  #

  # user name: actions-oidc:repo:quovadis-btp/btp-boosters:ref:refs/heads/main
  # the clientID (Audience) could be provided as input values, same goes for repo, workflow and ref values
  #
  OpenIDConnect_GITHUB = jsonencode({

        "apiVersion": "authentication.gardener.cloud/v1alpha1",
        "kind": "OpenIDConnect",
        "metadata": {
            "name": "gh-${local.cluster_id}"
        },
        "spec": {
            "issuerURL": "${var.GITHUB_ACTIONS_TOKEN_ISSUER}",
            "clientID": "gh-${local.cluster_id}",
            "usernameClaim": "sub",
            "usernamePrefix": "actions-oidc:",
            "requiredClaims": {
                "repository": "${var.GITHUB_ACTIONS_REPOSITORY}",
                "workflow": "${var.GITHUB_ACTIONS_WORKFLOW}"
                "ref": "${var.GITHUB_ACTIONS_REF}"
            }
        }
  })

  # https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/kubernetes-configuration#configure-kubernetes
  # https://developer.hashicorp.com/terraform/tutorials/cloud/dynamic-credentials
  # https://github.com/hashicorp-education/learn-terraform-dynamic-credentials/tree/main?tab=readme-ov-file
  #
  # "User" value is formatted as: 
/*
  organization:<MY-ORG-NAME>:project:<MY-PROJECT-NAME>:workspace:<MY-WORKSPACE-NAME>:run_phase:<plan|apply>.

  organization:quovadis:project:terraform-stories:workspace:runtime-context-quovadis-anywhere:run_phase:plan
  organization:quovadis:project:terraform-stories:workspace:runtime-context-quovadis-anywhere:run_phase:apply

  organization:quovadis:project:terraform-stories:workspace:runtime-context-41bb3a1e-2c13-454e-976f-d9734acad3c4:run_phase:plan
  organization:quovadis:project:terraform-stories:workspace:runtime-context-41bb3a1e-2c13-454e-976f-d9734acad3c4:run_phase:apply

  organization:quovadis:project:terraform-stories:workspace:runtime-context-89ebab58trial:run_phase:plan
  organization:quovadis:project:terraform-stories:workspace:runtime-context-89ebab58trial:run_phase:apply

  organization:quovadis:project:terraform-stories:workspace:runtime-context-1afe5b3btrial:run_phase:plan
  organization:quovadis:project:terraform-stories:workspace:runtime-context-1afe5b3btrial:run_phase:apply
*/  
  #
  OpenIDConnect_HCP = jsonencode({

        "apiVersion": "authentication.gardener.cloud/v1alpha1",
        "kind": "OpenIDConnect",
        "metadata": {
            "name": "terraform-cloud"
        },
        "spec": {
            "issuerURL": "https://app.terraform.io",
            "clientID": "terraform-cloud",
            "usernameClaim": "sub",
            "usernamePrefix": "-",
            "groupsClaim": "terraform_organization_name",
            "groupsPrefix": ""
        }
  })


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


resource "terraform_data" "bootstrap-tcf-oidc" {
  depends_on = [
       terraform_data.kubectl_getnodes
  ]

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
  input = [ 
      nonsensitive(local.OpenIDConnect_HCP) 
      ]

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
      OpenIDConnect='${self.input[0]}'
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


# https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax#the-self-object
# https://developer.hashicorp.com/terraform/language/resources/terraform-data
# https://developer.hashicorp.com/terraform/language/functions/nonsensitive
#
# bootstrap kyma openidconnect resource
#
resource "terraform_data" "bootstrap-kymaruntime-bot" {
  depends_on = [
       //terraform_data.provider_context,
       data.kubernetes_config_map_v1.sap-btp-operator-config
  ]

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
  input = [ 
      nonsensitive(local.OpenIDConnect), 
      nonsensitive(local.OpenIDConnect_PROD), 
      nonsensitive(local.OpenIDConnect_STAGE), 
      nonsensitive(local.OpenIDConnect_GITHUB)
      ]

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
      OpenIDConnect='${self.input[0]}'
      echo $(jq -r '.' <<< $OpenIDConnect)
      echo $OpenIDConnect

      echo | ./kubectl get nodes --kubeconfig $KUBECONFIG
      ./kubectl create ns $NAMESPACE --kubeconfig $KUBECONFIG --dry-run=client -o yaml | ./kubectl apply --kubeconfig $KUBECONFIG -f -
      ./kubectl label namespace $NAMESPACE istio-injection=enabled --kubeconfig $KUBECONFIG

      # a debug line until the OpenIDConnect CRD is installed via the oidc shoot extension
      #
      echo $(jq -r '.' <<< $OpenIDConnect ) >  bootstrap-kymaruntime-bot.json
      echo $OpenIDConnect | ./kubectl apply --kubeconfig $KUBECONFIG -n $NAMESPACE -f - 

      OpenIDConnect='${self.input[1]}'
      echo $OpenIDConnect
      echo $(jq -r '.' <<< $OpenIDConnect ) >  bootstrap-kymaruntime-prod.json
      echo $OpenIDConnect | ./kubectl apply --kubeconfig $KUBECONFIG -n $NAMESPACE -f - 

      OpenIDConnect='${self.input[2]}'
      echo $OpenIDConnect
      echo $(jq -r '.' <<< $OpenIDConnect ) >  bootstrap-kymaruntime-stage.json
      echo $OpenIDConnect | ./kubectl apply --kubeconfig $KUBECONFIG -n $NAMESPACE -f - 

      OpenIDConnect='${self.input[3]}'
      echo $OpenIDConnect
      echo $(jq -r '.' <<< $OpenIDConnect ) >  bootstrap-kymaruntime-stage.json
      echo $OpenIDConnect | ./kubectl apply --kubeconfig $KUBECONFIG -n $NAMESPACE -f - 

    else
      echo $crd
    fi

     )
   EOF
 }
}



data "http" "token-bot" {
  url = "${local.idp.url}/oauth2/token"
  method = "POST"
  request_headers = {
    Content-Type  = "application/x-www-form-urlencoded"
  }  
  request_body = "grant_type=password&username=${var.BTP_BOT_USER}&password=${var.BTP_BOT_PASSWORD}&client_id=${local.bot.clientid}&scope=groups,email"
}

/*
resource "local_sensitive_file" "headless-token-bot" {
  content  = data.http.token-bot.response_body
  filename = "headless-token-bot.json"
}*/

output "headless-token-bot" {
  value = data.http.token-bot.response_body
}

data "http" "token-secret-bot" {
  url = "${local.idp-secret.url}/oauth2/token"
  method = "POST"
  request_headers = {
    Content-Type  = "application/x-www-form-urlencoded"
  }  
  request_body = "grant_type=password&username=${var.BTP_BOT_USER}&password=${var.BTP_BOT_PASSWORD}&client_id=${local.bot-secret.clientid}&client_secret=${local.bot-secret.clientsecret}&scope=groups,email"
}

/*
resource "local_sensitive_file" "headless-token-bot-secret" {
  content  = data.http.token-secret-bot.response_body
  filename = "headless-token-bot-secret.json"
}*/

output "headless-token-bot-secret" {
  value = data.http.token-secret-bot.response_body
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

/*
resource "local_sensitive_file" "headless-token-bot-cert" {
  content  = data.http.token-cert-bot.response_body
  filename = "headless-token-bot-cert.json"
}
*/

output "headless-token-bot-cert" {
  value = data.http.token-cert-bot.response_body
}


# https://gist.github.com/ptesny/14f49f49e0fbe2a3143700ce707ee76b#72-sap-cloud-identity-services-as-a-custom-oidc-provider
#
locals {  

    kubeconfig_bot_cert = jsonencode({

        "apiVersion": "client.authentication.k8s.io/v1",
        "interactiveMode": "Never",
        "command": "bash",
        "args": [
            "-c",
             "set -e -o pipefail\n\nKEY='${local.bot-cert.key}'\nCERT='${local.bot-cert.certificate}'\nIDTOKEN=$(curl -X POST  \"${local.bot-cert.url}/oauth2/token\" \\\n--key <(echo \"$KEY\") \\\n--cert <(echo \"$CERT\") \\\n-H 'Content-Type: application/x-www-form-urlencoded' \\\n-d 'grant_type=password' \\\n-d 'username='\"${var.BTP_BOT_USER}\" \\\n-d 'password='\"${var.BTP_BOT_PASSWORD}\" \\\n-d 'client_id='\"${local.bot-cert.clientid}\" \\\n-d 'scope=groups, email' \\\n| jq -r '. | .id_token ' ) \n\n# Print decoded token information for debugging purposes\necho ::debug:: JWT content: \"$(echo \"$IDTOKEN\" | jq -c -R 'split(\".\") | .[1]\n| @base64d | fromjson')\" >&2\n\n\nEXP_TS=$(echo $IDTOKEN | jq -R 'split(\".\") | .[1] | @base64d | fromjson |\n.exp')\n\n# EXP_DATE=$(date -d @$EXP_TS --iso-8601=seconds)          \n\ncat << EOF\n{\n  \"apiVersion\": \"client.authentication.k8s.io/v1\",\n  \"kind\": \"ExecCredential\",\n  \"status\": {\n    \"token\": \"$IDTOKEN\"\n  }\n}\nEOF\n"
           ]

    })
             

    kubeconfig_bot_exec = jsonencode({
        "apiVersion": "client.authentication.k8s.io/v1",
        "interactiveMode": "Never",
        "command": "bash",
        "args": [
            "-c",
            "set -e -o pipefail\n\nIDTOKEN=$(curl -X POST  \"${local.bot.url}/oauth2/token\" \\\n-H 'Content-Type: application/x-www-form-urlencoded' \\\n-d 'grant_type=password' \\\n-d 'username='\"${var.BTP_BOT_USER}\" \\\n-d 'password='\"${var.BTP_BOT_PASSWORD}\" \\\n-d 'client_id='\"${local.bot.clientid}\" \\\n-d 'scope=groups, email' \\\n| jq -r '. | .id_token ' ) \n\n# Print decoded token information for debugging purposes\necho ::debug:: JWT content: \"$(echo \"$IDTOKEN\" | jq -c -R 'split(\".\") | .[1] | @base64d | fromjson')\" >&2\n\nEXP_TS=$(echo $IDTOKEN | jq -R 'split(\".\") | .[1] | @base64d | fromjson | .exp')\n# EXP_DATE=$(date -d @$EXP_TS --iso-8601=seconds)          \ncat << EOF\n{\n  \"apiVersion\": \"client.authentication.k8s.io/v1\",\n  \"kind\": \"ExecCredential\",\n  \"status\": {\n    \"token\": \"$IDTOKEN\"\n  }\n}\nEOF\n"
        ]
    })            

   gh_workflow = jsonencode({
          "name": "terraform-stories",
          "permissions": {
              "id-token": "write"
          },
          "on": {
              "workflow_dispatch": null
          },
          "jobs": {
              "apply-manifest": {
                  "runs-on": [
                      "self-hosted",
                      "solinas-ubuntu_22_04"
                  ],
                  "steps": [
                      {
                          "name": "Setup Kube Context",
                          "uses": "azure/k8s-set-context@v4",
                          "with": {
                              "method": "kubeconfig",
                              "kubeconfig": "\n\"string\"\n"
                          }
                      },
                      {
                          "name": "check permissions",
                          "run": "kubectl auth can-i --list --namespace quovadis-btp\nkubectl get nodes\nkubectl get pod -A\nkubectl get -n kyma-system kymas default -o json | jq '.spec.modules[] '\n"
                      }
                  ]
              }
          }
   })

    kubeconfig_gh_exec = jsonencode({

        "apiVersion": "client.authentication.k8s.io/v1",
        "interactiveMode": "Never",
        "command": "bash",
        "args": [
            "-c",
            "set -e -o pipefail\nOIDC_URL_WITH_AUDIENCE=\"$ACTIONS_ID_TOKEN_REQUEST_URL&audience=gh-${local.cluster_id}\"\nIDTOKEN=$(curl -sS \\\n  -H \"Authorization: Bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN\" \\\n  -H \"Accept: application/json; api-version=2.0\" \\\n  \"$OIDC_URL_WITH_AUDIENCE\" | jq -r .value)\n# Print decoded token information for debugging purposes\necho ::debug:: JWT content: \"$(echo \"$IDTOKEN\" | jq -c -R 'split(\".\") | .[1] | @base64d | fromjson')\" >&2\nEXP_TS=$(echo $IDTOKEN | jq -R 'split(\".\") | .[1] | @base64d | fromjson | .exp')\nEXP_DATE=$(date -d @$EXP_TS --iso-8601=seconds)\n# return token back to the credential plugin\ncat << EOF\n{\n  \"apiVersion\": \"client.authentication.k8s.io/v1\",\n  \"kind\": \"ExecCredential\",\n  \"status\": {\n    \"token\": \"$IDTOKEN\",\n    \"expirationTimestamp\": \"$EXP_DATE\"\n  }\n}\nEOF\n"
        ]

    })            



    kubeconfig_kyma_oidc = jsonencode({
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

   data = jsonencode(yamldecode(local.kyma_kubeconfig))
   query = "del(.users[] | .user | .exec) | .users[] |= . + { user: { exec: ${local.kubeconfig_bot_exec} } }"
}

output "kubeconfig_bot_exec" {
#  value = jsondecode(data.jq_query.kubeconfig_bot_exec.result)
  value = yamlencode(jsondecode(data.jq_query.kubeconfig_bot_exec.result))

  # https://stackoverflow.com/questions/58275233/terraform-depends-on-with-modules
  #
  depends_on = [ terraform_data.bootstrap-kymaruntime-bot ]
}

data "jq_query" "kubeconfig_bot_cert" {
   depends_on = [data.http.kubeconfig]

   data = jsonencode(yamldecode(local.kyma_kubeconfig))
   query = "del(.users[] | .user | .exec) | .users[] |= . + { user: { exec: ${local.kubeconfig_bot_cert} } }"
}

output "kubeconfig_prod_exec" {
#  value = jsondecode(data.jq_query.kubeconfig_bot_cert.result)
  value = yamlencode(jsondecode(data.jq_query.kubeconfig_bot_cert.result))

  # https://stackoverflow.com/questions/58275233/terraform-depends-on-with-modules
  #
  depends_on = [ terraform_data.bootstrap-kymaruntime-bot ]
}

// github workflow dynamic kubeconfig generation
//
data "jq_query" "kubeconfig_gh_exec" {
   depends_on = [data.http.kubeconfig]

   data = jsonencode(yamldecode(local.kyma_kubeconfig))
   query = "del(.users[] | .user | .exec) | .users[] |= . + { user: { exec: ${local.kubeconfig_gh_exec} } }"
}

output "kubeconfig_gh_exec" {
#  value = jsondecode(data.jq_query.kubeconfig_gh_exec.result)
  value = yamlencode(jsondecode(data.jq_query.kubeconfig_gh_exec.result))

  # https://stackoverflow.com/questions/58275233/terraform-depends-on-with-modules
  #
  depends_on = [ terraform_data.bootstrap-kymaruntime-bot ]
}

// github workflow generation
// https://github.com/hashicorp/terraform/issues/23322#issuecomment-1263778792
// https://blog.linoproject.net/terraform-study-notes-read-generate-and-modify-configuration-pt-2/

locals {
//  kubeconfig_gh_json = format("%s%s%s", "<<-EOT\n", data.jq_query.kubeconfig_gh_exec.result, "\nEOT\n")
  kubeconfig_gh_json = format("%s%s%s", "\n", data.jq_query.kubeconfig_gh_exec.result, "\n")
}

data "jq_query" "gh_workflow" {
   depends_on = [data.http.kubeconfig]

   data = local.gh_workflow
//   query = ". | .jobs[].steps[0].with |= . + { kubeconfig: ${data.jq_query.kubeconfig_gh_exec.result}   }"
//   query = ". | .jobs[].steps[0].with |= . + { kubeconfig: ${local.kubeconfig_gh_json} | tostring  }"
   query = ". | .jobs[].steps[0].with |= . + { kubeconfig: ${local.kubeconfig_gh_json} | tojson  }"
}

output "gh_workflow_json" {
  value = data.jq_query.gh_workflow.result

  # https://stackoverflow.com/questions/58275233/terraform-depends-on-with-modules
  #
  depends_on = [ terraform_data.bootstrap-kymaruntime-bot ]
}

output "gh_workflow" {
  value = yamlencode(jsondecode(data.jq_query.gh_workflow.result))

  # https://stackoverflow.com/questions/58275233/terraform-depends-on-with-modules
  #
  depends_on = [ terraform_data.bootstrap-kymaruntime-bot ]
}
