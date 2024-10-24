
resource "btp_subaccount_entitlement" "connectivity" {
  subaccount_id = data.btp_subaccount.context.id
  service_name  = "connectivity"
  plan_name     = "connectivity_proxy"
}


resource "btp_subaccount_entitlement" "kymaruntime" {
  subaccount_id = data.btp_subaccount.context.id
  service_name  = "kymaruntime"
  plan_name     = var.BTP_KYMA_PLAN
  amount        = 1
}


# Fetch all available environments for the subaccount
#
data "btp_subaccount_environments" "all" {
  subaccount_id = data.btp_subaccount.context.id
  depends_on    = [btp_subaccount_entitlement.kymaruntime]
}

# Take the first kyma region from the first kyma environment if no kyma instance parameters are provided
resource "null_resource" "cache_kyma_region" {
  count   = var.BTP_KYMA_PLAN != "trial" ? 1 : 0
  triggers = {
    region = var.BTP_KYMA_REGION != "" ? var.BTP_KYMA_REGION  : jsondecode([for env in data.btp_subaccount_environments.all.values : env if env.service_name == "kymaruntime" && env.environment_type == "kyma" && env.plan_name == var.BTP_KYMA_PLAN][0].schema_create).parameters.properties.region.enum[0]
  }

/*
  lifecycle {
    ignore_changes = all
  }
  */
}

resource "null_resource" "cache_kyma_machine_type" {
  count   = var.BTP_KYMA_PLAN != "trial" ? 1 : 0

  triggers = {
    machineType = var.BTP_KYMA_MACHINE_TYPE != "" ? var.BTP_KYMA_MACHINE_TYPE  : jsondecode([for env in data.btp_subaccount_environments.all.values : env if env.service_name == "kymaruntime" && env.environment_type == "kyma" && env.plan_name == var.BTP_KYMA_PLAN][0].schema_create).parameters.properties.machineType.enum[1]
  }

/*
  lifecycle {
    ignore_changes = all
  }*/
}

output "kyma_machine_types" {

  value = var.BTP_KYMA_PLAN != "trial" ? jsondecode([for env in data.btp_subaccount_environments.all.values : env if env.service_name == "kymaruntime" && env.environment_type == "kyma" && env.plan_name == var.BTP_KYMA_PLAN][0].schema_create).parameters.properties.machineType.enum : ["trial"]
}

output "kyma_cluster_regions" {

  value = var.BTP_KYMA_PLAN != "trial" ? jsondecode([for env in data.btp_subaccount_environments.all.values : env if env.service_name == "kymaruntime" && env.environment_type == "kyma" && env.plan_name == var.BTP_KYMA_PLAN][0].schema_create).parameters.properties.region.enum : ["trial"]
}

locals {
  machineType = one(null_resource.cache_kyma_machine_type[*].triggers.machineType)
  cluster_region = one(null_resource.cache_kyma_region[*].triggers.region)


  bot_cluster_admins = [for cluster_admin in var.cluster_admins : "bot-identity:${cluster_admin}"]

  administrators = concat(var.cluster_admins, local.bot_cluster_admins, tolist([var.BTP_BOT_USER, format("bot-identity:%s",var.BTP_BOT_USER), local.user_plan, local.user_apply, local.user_gha]) )
}

output "administrators" {
  value = nonsensitive(local.administrators)
}

output "bot_admins" {
  value = nonsensitive(local.bot_cluster_admins)
}


locals {
  modules = [
          {
            "name": "api-gateway",
            "channel": "regular"
          },
          {
            "name": "istio",
            "channel": "regular"
          },
          {
            "name": "btp-operator",
            "channel": "regular"
          },
          {
            "name": "serverless",
            "channel": "regular"
          },
          {
            "name": "connectivity-proxy",
            "channel": "regular"
          }
/*      
        ,
        {
            "name": "cloud-manager",
            "channel": "regular"
        }
*/ 
        ]
}


# https://developer.hashicorp.com/terraform/language/resources/provisioners/null_resource
# https://serverfault.com/questions/988222/where-to-put-local-exec-command-to-run-before-terraform-destroy
# https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax#destroy-time-provisioners
#
resource "btp_subaccount_environment_instance" "kyma" {
  count            = var.BTP_KYMA_DRY_RUN ? 0 : 1
  depends_on       = [
      btp_subaccount_service_binding.ias-local-binding, 
      btp_subaccount_service_binding.ias-local-binding-secret, 
      btp_subaccount_service_binding.ias-local-binding-cert, 
      btp_subaccount_entitlement.connectivity
  ]

  subaccount_id    = data.btp_subaccount.context.id
  name             = "${var.BTP_SUBACCOUNT}-kyma"
  environment_type = "kyma"
  service_name     = btp_subaccount_entitlement.kymaruntime.service_name
  plan_name        = btp_subaccount_entitlement.kymaruntime.plan_name
  parameters       = jsonencode({
      "name": "${var.BTP_SUBACCOUNT}-${var.BTP_KYMA_NAME}",
      "region": var.BTP_KYMA_PLAN != "trial" ? local.cluster_region : null,
      "machineType": var.BTP_KYMA_PLAN != "trial" ? local.machineType : null,
      "autoScalerMin": var.BTP_KYMA_PLAN != "trial" ? 3 : 1,
      "autoScalerMax": var.BTP_KYMA_PLAN != "trial" ? 5 : 1,
      "modules": {
        "list": local.modules
      },
      "administrators": local.administrators,
      "oidc": {
        "clientID": jsondecode(btp_subaccount_service_binding.ias-local-binding.credentials).clientid,
        "groupsClaim": "groups",
        "issuerURL": jsondecode(btp_subaccount_service_binding.ias-local-binding.credentials).url,
        "signingAlgs": [
          "RS256"
        ],
        "usernameClaim": "sub",
        "usernamePrefix": "-"
      }
  })
  timeouts = {
    create = "60m"
    update = "30m"
    delete = "60m"
  }

/*
  // will need to make sure there is a valid kubeconfig at the time of resource destruction
  //
  provisioner "local-exec" {
    # delete the connectivity proxy module if present
    when        = destroy
    on_failure  = continue

    interpreter = ["/bin/bash", "-c"]
     command = <<EOF
       (
      KUBECONFIG=kubeconfig-headless.yaml
      MODULE=connectivity-proxy
      set -e -o pipefail ;\
      curl -LO https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl
      chmod +x kubectl

      ./kubectl --kubeconfig $KUBECONFIG -n kyma-system rollout status statefulset connectivity-proxy --timeout=5m

      KYMAS_DEFAULT_CONFIG=$(./kubectl get -n kyma-system kymas default --kubeconfig $KUBECONFIG -o json)
      NEW_KYMAS_CONFIG=$(echo $KYMAS_DEFAULT_CONFIG | jq --arg m "$MODULE" 'del(.spec.modules[] | select(.name == $m) )' )
      echo $NEW_KYMAS_CONFIG
      echo $NEW_KYMAS_CONFIG | ./kubectl apply --kubeconfig $KUBECONFIG -n kyma-system -f -
      ./kubectl wait --for=delete --kubeconfig $KUBECONFIG -n kyma-system statefulset/connectivity-proxy --timeout=480s
       )
     EOF
  } 
/*/

}

#
# https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep#delay-destroy-usage
#
# The btp_subaccount_environment_instance.kyma resource will destroy (at least) 60 seconds after null_resource.next

resource "time_sleep" "wait_180_seconds" {
  depends_on = [btp_subaccount_environment_instance.kyma]

  destroy_duration = "60s"
}

# This resource will create (potentially immediately) after btp_subaccount_environment_instance.kyma
resource "terraform_data" "next" {
//resource "null_resource" "next" {
  depends_on = [time_sleep.wait_180_seconds]

  input = local.kubeconfig

  // will need to make sure there is a valid kubeconfig at the time of resource destruction
  //
  provisioner "local-exec" {
    # delete the connectivity proxy module if present
    when        = destroy
    on_failure  = continue

    interpreter = ["/bin/bash", "-c"]
     command = <<EOF
       (
      KUBECONFIG=kubeconfig-headless.yaml
      MODULE=connectivity-proxy
      set -e -o pipefail ;\
      curl -LO https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl
      chmod +x kubectl

      echo '${self.input}'  > kubeconfig-headless.yaml

      ./kubectl --kubeconfig $KUBECONFIG -n kyma-system rollout status statefulset connectivity-proxy --timeout=5m

      KYMAS_DEFAULT_CONFIG=$(./kubectl get -n kyma-system kymas default --kubeconfig $KUBECONFIG -o json)
      NEW_KYMAS_CONFIG=$(echo $KYMAS_DEFAULT_CONFIG | jq --arg m "$MODULE" 'del(.spec.modules[] | select(.name == $m) )' )
      echo $NEW_KYMAS_CONFIG
      echo $NEW_KYMAS_CONFIG | ./kubectl apply --kubeconfig $KUBECONFIG -n kyma-system -f -
      
      ./kubectl wait --for=delete --kubeconfig $KUBECONFIG -n kyma-system statefulset/connectivity-proxy --timeout=5m
       )
     EOF
  }   
}


resource "terraform_data" "kyma" {
  # Replacement of any instance of the cluster requires re-provisioning
  triggers_replace = btp_subaccount_environment_instance.kyma[*]
  depends_on = [time_sleep.wait_180_seconds]

  input = local.labels
  //command = "echo 'terraform_data.kyma provisioner'"

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = "echo '${self.input}'"
  }
}

resource "terraform_data" "kyma_env" {
  triggers_replace = [
        terraform_data.kubectl_getnodes
  ]

  input = [
        nonsensitive(local.dashboard_url),
        nonsensitive(local.labels),
        nonsensitive(local.parameters)
      ]
 
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOF
     (
      dashboard_url='${self.input[0]}'
      echo "$dashboard_url"
      # echo $(jq -r '.' <<< $dashboard_url)
      # echo $(jq -r '.' <<< $dashboard_url ) >  dashboard_url.json

      labels='${self.input[1]}'
      echo "$labels" | jq -r '.'
      echo "$labels" | jq -r '.' >  labels.json
      # echo $(jq -r '.' <<< $labels)
      # echo $(jq -r '.' <<< $labels ) >  labels.json

      parameters='${self.input[2]}'
      # echo "$parameters"
      # echo $(jq -r '.' <<< $parameters)
      echo $parameters | jq -r '.'
      echo $parameters | jq -r '.' >  parameters.json
      #echo $(jq -r '.' <<< $parameters ) >  parameters.json

     )
    EOF

  }
}

# https://stackoverflow.com/a/74460150
locals {
  dashboard_url = one(btp_subaccount_environment_instance.kyma[*].dashboard_url)
  labels = one(btp_subaccount_environment_instance.kyma[*].labels)
  parameters = one(btp_subaccount_environment_instance.kyma[*].parameters)
}

output "kyma_dashboard_url" {
  value = nonsensitive(local.dashboard_url)
}

output "kyma_labels" {
  value = nonsensitive(jsondecode(local.labels))
}

output "kyma_parameters" {
  value = nonsensitive(jsondecode(local.parameters))
}

# https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http
# https://developer.hashicorp.com/terraform/language/expressions/custom-conditions#preconditions-and-postconditions
#
data "http" "kubeconfig" {
  //provider = http-full

  depends_on = [btp_subaccount_environment_instance.kyma]
  
  url = local.labels != null ? jsondecode(local.labels)["KubeconfigURL"] : "https://sap.com"

  lifecycle {
    postcondition {
      condition     = can(regex("kind: Config",self.response_body))
      error_message = "Invalid content of downloaded kubeconfig"
    }
    postcondition {
      condition     = contains([200], self.status_code)
      error_message = self.response_body
    }
  } 

}

# yaml formatted default (oid-based) kyma kubeconfig
locals {
  kyma_kubeconfig = data.http.kubeconfig.response_body
}


/*
resource "local_sensitive_file" "kubeconfig-oidc" {
  #filename = ".${data.btp_subaccount.context.id}-${var.BTP_KYMA_NAME}.kubeconfig"
  filename = "kubeconfig-oidc.json"
  content  = jsonencode(yamldecode(local.kyma_kubeconfig))
}

resource "local_file" "kubeconfig_url" {
  depends_on = [btp_subaccount_environment_instance.kyma]
  content    = local.labels != null ? jsondecode(local.labels).KubeconfigURL : "dry run"
  filename   = "kubeconfig_url.txt"
}
*/


output "kubeconfig-oidc" {
  description = "original json-formatted oidc kubeconfig"
  value       = jsonencode(yamldecode(local.kyma_kubeconfig))
}

output "kyma-kubeconfig" {
  description = "original oidc yaml formatted kubeconfig"
  value       = local.kyma_kubeconfig
}

output "kyma-kubeconfig-url" {
  description = "deep link to download kubeconfig URL"
  value       = local.labels != null ? jsondecode(local.labels).KubeconfigURL : "dry run"
}

# https://registry.terraform.io/browse/providers?tier=official
# https://stackoverflow.com/questions/75400238/what-is-the-ideal-way-to-json-stringify-in-terraform
# https://stackoverflow.com/questions/74906811/terrafrom-output-in-data-eof

locals {
  #id_token = jsonencode(jsondecode(data.http.token.response_body).id_token)
  #id_token = jsonencode(jsondecode(data.http.token-secret.response_body).id_token)
  id_token = jsonencode(jsondecode(data.http.token-cert.response_body).id_token)
}

# https://registry.terraform.io/providers/massdriver-cloud/jq/latest/docs/data-sources/query
#
data "jq_query" "kubeconfig" {
   depends_on = [btp_subaccount_environment_instance.kyma]
   data = jsonencode(yamldecode(local.kyma_kubeconfig))
   query = "del(.users[] | .user | .exec) | .users[] |= . + { user: { token: ${local.id_token} } }"
}

output "kubeconfig" {
  description = "headless, short lived token based kubeconfig"
  value       = jsondecode(data.jq_query.kubeconfig.result)
}

output "kubeconfig_raw" {
  value = data.jq_query.kubeconfig.result
}

/*
resource "local_sensitive_file" "kubeconfig-headless" {
  filename = "kubeconfig-headless.json"
  content  = data.jq_query.kubeconfig.result
}

resource "local_sensitive_file" "kubeconfig-yaml" {
  filename = "kubeconfig.yaml"
  content  = yamlencode(jsondecode(data.jq_query.kubeconfig.result) )
}

resource "null_resource" "write_yaml" {
  triggers = {
    always_run = "${timestamp()}"
  }
 provisioner "local-exec" {
   command = <<EOF
     echo "${local.kubeconfig}" > config.yaml
EOF
 }
}
*/


# headless kubeconfig
locals {
  kubeconfig  = yamlencode(jsondecode(data.jq_query.kubeconfig.result) )
}

# https://spacelift.io/blog/terraform-yaml#what-is-the-yamldecode-function-in-terraform
# https://developer.hashicorp.com/terraform/language/resources/terraform-data#the-terraform_data-managed-resource-type
#
resource "terraform_data" "write_yaml" {
  triggers_replace = {
    always_run = "${timestamp()}"
  }
 provisioner "local-exec" {
   command = <<EOF
     echo "${local.kubeconfig}" > config.yaml
EOF
 }
}


# https://stackoverflow.com/questions/72607500/how-to-handle-multiple-lines-within-a-command-block-in-terraform
# https://stackoverflow.com/questions/57041699/how-to-use-bash-commands-in-terraform-template-file-variables
# https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external
#
resource "null_resource" "kubectl_getnodes" {
  depends_on = [btp_subaccount_environment_instance.kyma]

  triggers = {
    always_run = "${timestamp()}"
  }
 provisioner "local-exec" {
   interpreter = ["/bin/bash", "-c"]
   command = <<EOH
     (
    set -e -o pipefail
    curl -o jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
    chmod 0755 jq
    curl -LO https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl
    chmod +x kubectl
    curl -LO https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    mv argocd-linux-amd64 argocd
    chmod +x argocd
    echo | ls -l
     )
   EOH
 }
}

#
# get-cluster-zones
#
resource "terraform_data" "kubectl_getnodes" {
  depends_on = [btp_subaccount_environment_instance.kyma, null_resource.kubectl_getnodes]

  triggers_replace = {
    always_run = "${timestamp()}"
  }
 provisioner "local-exec" {
   interpreter = ["/bin/bash", "-c"]
   command = <<EOF
     (
    set -e -o pipefail ;\
    echo "${local.kubeconfig}" > kubeconfig-headless.yaml
    #echo | ./kubectl get nodes --kubeconfig kubeconfig-headless.yaml

    ## get-cluster-zones:
    echo | ./kubectl get nodes -o custom-columns=NAME:.metadata.name,REGION:".metadata.labels.topology\.kubernetes\.io/region",ZONE:".metadata.labels.topology\.kubernetes\.io/zone" --kubeconfig kubeconfig-headless.yaml
    
    #echo | ./kubectl resource-capacity --kubeconfig kubeconfig-headless.yaml

     )
   EOF
 }
}

# https://www.gnu.org/software/bash/manual/bash.html
resource "terraform_data" "argocd_bootstrap" {

/*
  lifecycle {
    replace_triggered_by = [
      terraform_data.replacement
    ]
  }
 */ 
  
  triggers_replace = [
        btp_subaccount_environment_instance.kyma,
        terraform_data.kubectl_getnodes,
        local_sensitive_file.argocd_config
  ]

 provisioner "local-exec" {
   interpreter = ["/bin/bash", "-c"]
   command = "${path.module}/argocd-bootstrap.sh"
 }
}


data "http" "argocd_token" {
  url = "${var.argocd_tokenurl}"
  method = "POST"
  request_headers = {
    Content-Type  = "application/x-www-form-urlencoded"
  }  
  request_body = "grant_type=password&username=${var.argocd_username}&password=${var.argocd_password}&client_id=${var.argocd_clientid}&scope=groups email"
}

locals {
  argocd_config = jsonencode({

    "contexts": [
        {
            "name": "${var.argocd_url}",
            "server": "${var.argocd_url}",
            "user": "${var.argocd_url}"
        }
    ],
    "current-context": "${var.argocd_url}",
    "servers": [
        {
            "grpc-web-root-path": "",
            "server": "${var.argocd_url}"
        }
    ],
    "users": [
        {
            "auth-token": jsondecode(data.http.argocd_token.response_body).id_token,
            "name": "${var.argocd_url}",
            "refresh-token": jsondecode(data.http.argocd_token.response_body).refresh_token
        }
    ]
  })
}

resource "local_sensitive_file" "argocd_config" {
  content         = local.argocd_config
  file_permission = "0600"
  filename        = "argocd_config.json"
}


# https://discuss.hashicorp.com/t/is-there-any-way-to-inspect-module-variables-and-outputs/25702
#
output "argocd_config" {
  value = jsondecode(local.argocd_config)
}

output "argocd_token" {
  value = jsondecode(data.http.argocd_token.response_body)
}

/*
// the argo_cd information could be fetched from the argocd service bindings - TO DO
// 
data "external" "argocd-bootstrap" {
  depends_on = [
         terraform_data.kubectl_getnodes
     ]

  program = ["bash", "${path.module}/argocd-bootstrap2.sh"]

  query = {
    username = "${var.argocd_username}"
    password = "${var.argocd_password}"
    token = "${var.argocd_tokenurl}"
    host = "${var.argocd_url}"
    client_id = "${var.argocd_clientid}"
  }
}
*/



# https://developer.hashicorp.com/terraform/language/state/remote-state-data#the-terraform_remote_state-data-source
# https://spacelift.io/blog/terraform-data-sources-how-they-are-utilised
# https://ourcloudschool.medium.com/read-terraform-provisioned-resources-with-terraform-remote-state-datasource-ab9cf882ab63
# https://spacelift.io/blog/terraform-remote-state
# https://fabianlee.org/2023/08/06/terraform-terraform_remote_state-to-pass-values-to-other-configurations/
#
data "terraform_remote_state" "provider_context" {
  count   = var.provider_context_backend != "tfe" ? 1 : 0

  backend = var.provider_context_backend // "kubernetes" 
  config  = var.provider_context_backend == "kubernetes" ? var.provider_context_kubernetes_backend_config : var.provider_context_local_backend_config 
}

# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/outputs?ajs_aid=3951d9c3-6a9a-4a4d-826b-b5a7fc7daf9f&product_intent=terraform
#
data "tfe_outputs" "provider_context" {
  count        = var.provider_context_backend == "tfe" ? 1 : 0

  organization = var.provider_context_organization
  workspace    = var.provider_context_workspace
}

// this provider context can be null
// https://stackoverflow.com/a/74353092
//
locals {
  remote_backend = try(one(data.terraform_remote_state.provider_context[*].outputs.provider_k8s), null)
  tfe_backend    = try(one(data.tfe_outputs.provider_context[*].values.provider_k8s), null)

  provider_k8s = local.remote_backend != null ? local.remote_backend : local.tfe_backend

}

# hooking up selected namespaces with the provider context
#
resource "terraform_data" "provider_context" {
  depends_on = [
    terraform_data.kubectl_getnodes, 
    terraform_data.argocd_bootstrap
  ]

/*
  triggers_replace = {
    always_run = "${timestamp()}"
  }
*/

  triggers_replace = [
        terraform_data.kubectl_getnodes
  ]

 input = local.provider_k8s != null ? nonsensitive(jsonencode(local.provider_k8s)) : ""
 ## TOKEN=${local.provider_k8s}

 provisioner "local-exec" {
   interpreter = ["/bin/bash", "-c"]
   command = <<EOF
     (
    KUBECONFIG=kubeconfig-headless.yaml
    NAMESPACE=quovadis-btp
    NAMESPACE2=montypython
    NAMESPACE3=montypython-xsuaa-mt

    set -e -o pipefail ;\

    TOKEN=${self.input}
    echo $TOKEN

    echo | ./kubectl get nodes --kubeconfig $KUBECONFIG ;\
    ./kubectl create ns $NAMESPACE --kubeconfig $KUBECONFIG --dry-run=client -o yaml | ./kubectl apply --kubeconfig $KUBECONFIG -f -
    ./kubectl label namespace $NAMESPACE istio-injection=enabled --kubeconfig $KUBECONFIG

    ./kubectl create ns $NAMESPACE2 --kubeconfig $KUBECONFIG --dry-run=client -o yaml | ./kubectl apply --kubeconfig $KUBECONFIG -f -
    ./kubectl label namespace $NAMESPACE2 istio-injection=enabled --kubeconfig $KUBECONFIG

    ./kubectl create ns $NAMESPACE3 --kubeconfig $KUBECONFIG --dry-run=client -o yaml | ./kubectl apply --kubeconfig $KUBECONFIG -f -
    ./kubectl label namespace $NAMESPACE3 istio-injection=enabled --kubeconfig $KUBECONFIG

    echo | ./kubectl wait --for condition=established crd kymas.operator.kyma-project.io -n kyma-system --timeout=480s --kubeconfig $KUBECONFIG

    echo | ./kubectl wait --for=jsonpath='{.status.modules[?(@.name=="api-gateway")].state}'=Ready kyma default -n kyma-system --timeout 5m --kubeconfig $KUBECONFIG
    while [ "$(./kubectl --kubeconfig $KUBECONFIG -n kyma-system get deployment api-gateway-controller-manager --ignore-not-found)" = "" ]
    do 
      echo "deployments.apps - api-gateway-controller-manager - not found"
      sleep 1
    done
    echo | ./kubectl --kubeconfig $KUBECONFIG -n kyma-system rollout status deployment api-gateway-controller-manager --timeout 5m
    echo | ./kubectl wait --for condition=established crd apigateways.operator.kyma-project.io --timeout=480s --kubeconfig $KUBECONFIG

    echo | ./kubectl get apigateways/default --kubeconfig $KUBECONFIG --ignore-not-found

    while [ "$(./kubectl --kubeconfig $KUBECONFIG -n kyma-system get gateway kyma-gateway --ignore-not-found)" = "" ]
    do 
      echo "kyma-gateway - not found"
      sleep 1
    done


    INDEX=$(./kubectl get -n kyma-system kyma default --kubeconfig $KUBECONFIG -o json | jq '.spec.modules | map(.name == "btp-operator") | index(true)' )
    echo $INDEX

    echo | ./kubectl wait --for=jsonpath='{.status.modules[?(@.name=="btp-operator")].state}'=Ready kyma default -n kyma-system --timeout 5m --kubeconfig $KUBECONFIG
    while [ "$(./kubectl --kubeconfig $KUBECONFIG -n kyma-system get deployment sap-btp-operator-controller-manager --ignore-not-found)" = "" ]
    do 
      echo "deployments.apps - sap-btp-operator-controller-manager - not found"
      sleep 1
    done
    echo | ./kubectl --kubeconfig $KUBECONFIG -n kyma-system rollout status deployment sap-btp-operator-controller-manager --timeout 5m

    echo | ./kubectl wait --for condition=established crd serviceinstances.services.cloud.sap.com -n kyma-system --timeout=480s --kubeconfig $KUBECONFIG
    echo | ./kubectl wait --for condition=established crd servicebindings.services.cloud.sap.com -n kyma-system --timeout=480s --kubeconfig $KUBECONFIG

    SECRET=$(./kubectl get secret sap-btp-service-operator -n kyma-system --kubeconfig $KUBECONFIG -o json )
    echo $SECRET

    if [ "$TOKEN" = "" ]
    then
      echo "provider_k8s is empty"
    else
      CONFIG=$(echo $SECRET | jq --arg token "$TOKEN"  ' .data |= . + { "clientid": $token | fromjson | .clientid , "clientsecret": $token | fromjson | .clientsecret, "tokenurl": $token | fromjson | .tokenurl , "sm_url": $token | fromjson | .sm_url }' )
      echo $CONFIG
      echo $CONFIG | jq 'del(.metadata["namespace","creationTimestamp","resourceVersion","uid", "selfLink", "ownerReferences", "annotations", "labels"])' \
      | ./kubectl apply --kubeconfig $KUBECONFIG -n $NAMESPACE -f - 
      echo $CONFIG | jq 'del(.metadata["namespace","creationTimestamp","resourceVersion","uid", "selfLink", "ownerReferences", "annotations", "labels"])' \
      | ./kubectl apply --kubeconfig $KUBECONFIG -n $NAMESPACE2 -f - 
      echo $CONFIG | jq 'del(.metadata["namespace","creationTimestamp","resourceVersion","uid", "selfLink", "ownerReferences", "annotations", "labels"])' \
      | ./kubectl apply --kubeconfig $KUBECONFIG -n $NAMESPACE3 -f - 
    fi

    while [ "$(./kubectl api-versions --kubeconfig $KUBECONFIG | grep services.cloud.sap.com/v1 )" = "" ]
    do
     echo "services.cloud.sap.com/v1 - not found"
     sleep 1
    done
    echo | ./kubectl api-versions --kubeconfig $KUBECONFIG | grep services.cloud.sap.com/v1
     )
   EOF
 }
}

// https://stackoverflow.com/a/58277124
// https://stackoverflow.com/questions/58275233/terraform-depends-on-with-modules
//
output "provider_context" {
  depends_on = [terraform_data.provider_context]

  value = try(jsondecode(terraform_data.provider_context.output), "")

}
