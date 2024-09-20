
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


/*
  btp list accounts/available-environment | jq -r '.availableEnvironments[] | select(.serviceName == "kymaruntime" and .planName =="$(KYMARUNTIME_PLAN)") | .createSchema | fromjson | { machineType: .parameters.properties.machineType.enum[1], region: .parameters.properties.region.enum[0] }' > kyma-params.json
*/

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

  lifecycle {
    ignore_changes = all
  }
}

resource "null_resource" "cache_kyma_machine_type" {
  count   = var.BTP_KYMA_PLAN != "trial" ? 1 : 0

  triggers = {
    machineType = var.BTP_KYMA_MACHINE_TYPE != "" ? var.BTP_KYMA_MACHINE_TYPE  : jsondecode([for env in data.btp_subaccount_environments.all.values : env if env.service_name == "kymaruntime" && env.environment_type == "kyma" && env.plan_name == var.BTP_KYMA_PLAN][0].schema_create).parameters.properties.machineType.enum[1]
  }

  lifecycle {
    ignore_changes = all
  }
}

locals {
  machineType = one(null_resource.cache_kyma_machine_type[*].triggers.machineType)
  cluster_region = one(null_resource.cache_kyma_region[*].triggers.region)
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
      "administrators": var.cluster_admins,
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

      kubectl --kubeconfig $KUBECONFIG -n kyma-system rollout status statefulset connectivity-proxy --timeout=5m

      KYMAS_DEFAULT_CONFIG=$(kubectl get -n kyma-system kymas default --kubeconfig $KUBECONFIG -o json)
      NEW_KYMAS_CONFIG=$(echo $KYMAS_DEFAULT_CONFIG | jq --arg m "$MODULE" 'del(.spec.modules[] | select(.name == $m) )' )
      echo $NEW_KYMAS_CONFIG
      echo $NEW_KYMAS_CONFIG | kubectl apply --kubeconfig $KUBECONFIG -n kyma-system -f -
      kubectl wait --for=delete --kubeconfig $KUBECONFIG -n kyma-system statefulset/connectivity-proxy --timeout=180s
       )
     EOF
  } 
*/

}

#
# https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep#delay-destroy-usage
#
# The btp_subaccount_environment_instance.kyma resource will destroy (at least) 180 seconds after null_resource.next

resource "time_sleep" "wait_180_seconds" {
  depends_on = [btp_subaccount_environment_instance.kyma]

  destroy_duration = "60s"
}

# This resource will create (potentially immediately) after btp_subaccount_environment_instance.kyma
resource "null_resource" "next" {
  depends_on = [time_sleep.wait_180_seconds]

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

      kubectl --kubeconfig $KUBECONFIG -n kyma-system rollout status statefulset connectivity-proxy --timeout=5m

      KYMAS_DEFAULT_CONFIG=$(kubectl get -n kyma-system kymas default --kubeconfig $KUBECONFIG -o json)
      NEW_KYMAS_CONFIG=$(echo $KYMAS_DEFAULT_CONFIG | jq --arg m "$MODULE" 'del(.spec.modules[] | select(.name == $m) )' )
      echo $NEW_KYMAS_CONFIG
      echo $NEW_KYMAS_CONFIG | kubectl apply --kubeconfig $KUBECONFIG -n kyma-system -f -
      
      kubectl wait --for=delete --kubeconfig $KUBECONFIG -n kyma-system statefulset/connectivity-proxy --timeout=180s
       )
     EOF
  }   
}


resource "terraform_data" "kyma" {
  # Replacement of any instance of the cluster requires re-provisioning
  triggers_replace = btp_subaccount_environment_instance.kyma[*]
  depends_on = [time_sleep.wait_180_seconds]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "echo 'terraform_data.kyma provisioner'"
  }
}

# https://stackoverflow.com/a/74460150
locals {
  labels = one(btp_subaccount_environment_instance.kyma[*].labels)
}

data "http" "kubeconfig" {
  depends_on = [btp_subaccount_environment_instance.kyma]
  url = local.labels != null ? jsondecode(local.labels)["KubeconfigURL"] : "https://sap.com"
}

resource "local_sensitive_file" "kubeconfig-oidc" {
  #filename = ".${data.btp_subaccount.context.id}-${var.BTP_KYMA_NAME}.kubeconfig"
  filename = "kubeconfig-oidc.json"
  content  = jsonencode(yamldecode(data.http.kubeconfig.response_body))
}

resource "local_file" "kubeconfig_url" {
  depends_on = [btp_subaccount_environment_instance.kyma]
  #content    = jsondecode(btp_subaccount_environment_instance.kyma[0].labels).KubeconfigURL
  content    = local.labels != null ? jsondecode(local.labels).KubeconfigURL : "dry run"
  filename   = "kubeconfig_url.txt"
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
   data = jsonencode(yamldecode(data.http.kubeconfig.response_body))
   query = "del(.users[] | .user | .exec) | .users[] |= . + { user: { token: ${local.id_token} } }"
}

output "kubeconfig" {
  value = jsondecode(data.jq_query.kubeconfig.result)
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
     echo "${local.kubeconfig}" > config2.yaml
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
    curl -sSL https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    chmod +x argocd
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
    #echo | kubectl get nodes --kubeconfig kubeconfig-headless.yaml

    ## get-cluster-zones:
    echo | kubectl get nodes -o custom-columns=NAME:.metadata.name,REGION:".metadata.labels.topology\.kubernetes\.io/region",ZONE:".metadata.labels.topology\.kubernetes\.io/zone" --kubeconfig kubeconfig-headless.yaml
    
    echo | kubectl resource-capacity --kubeconfig kubeconfig-headless.yaml

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
  value = local.argocd_config
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

/*  
resource "btp_subaccount_entitlement" "postgresql" {
  subaccount_id = data.btp_subaccount.context.id
  service_name  = "postgresql-db"
  plan_name     = "trial"
  amount        = 1
}
*/



resource "terraform_data" "httpbin" {
  depends_on = [terraform_data.kubectl_getnodes,terraform_data.provider_context]

/*
  triggers_replace = {
    always_run = "${timestamp()}"
  }
*/

  triggers_replace = [
        btp_subaccount_environment_instance.kyma,
        terraform_data.kubectl_getnodes
  ]

 provisioner "local-exec" {
   interpreter = ["/bin/bash", "-c"]
   command = <<EOF
     (
    KUBECONFIG=kubeconfig-headless.yaml
    NAMESPACE=quovadis-btp

    set -e -o pipefail
    HTTPBIN=$(kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE get deployment httpbin --ignore-not-found)
    if [ "$HTTPBIN" = "" ]
    then
      kubectl create ns $NAMESPACE --kubeconfig $KUBECONFIG --dry-run=client -o yaml | kubectl apply --kubeconfig $KUBECONFIG -f -
      kubectl label namespace $NAMESPACE istio-injection=enabled --kubeconfig $KUBECONFIG
      kubectl -n $NAMESPACE create -f https://raw.githubusercontent.com/istio/istio/master/samples/httpbin/httpbin.yaml --kubeconfig $KUBECONFIG

      while [ "$(kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE get deployment httpbin --ignore-not-found)" = "" ]
      do 
        echo "no deployment httpbin"
        sleep 1
      done      
    fi

    HTTPBIN=$(kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE rollout status deployment httpbin --timeout 5m)
    echo $HTTPBIN 

     )
   EOF
 }
}

# https://www.gnu.org/software/gawk/manual/html_node/Print-Examples.html
# https://stackoverflow.com/questions/40321035/remove-escape-sequence-characters-like-newline-tab-and-carriage-return-from-jso
#     jq -r '.spec.parameters.allow_access | gsub("[\\n\\t]"; ";") '
resource "terraform_data" "egress_ips" {
  depends_on = [terraform_data.kubectl_getnodes]

/*
  triggers_replace = {
    always_run = "${timestamp()}"
  }
*/

  triggers_replace = [
        btp_subaccount_environment_instance.kyma,
        terraform_data.kubectl_getnodes
  ]

  input = nonsensitive(
    jsonencode({
      "apiVersion": "services.cloud.sap.com/v1",
      "kind": "ServiceInstance",
      "metadata": {
          "name": "postgresql"
      },
      "spec": {
          "serviceOfferingName": "postgresql-db",
          "servicePlanName": "trial",
          "parameters": {
              "region": "us-east-1",
              "allow_access": ""
          }
      } 
    })
  )  

 provisioner "local-exec" {
   interpreter = ["/bin/bash", "-c"]
   command = <<EOF
     (
    set -e -o pipefail ;\
    for zone in $(kubectl get nodes --kubeconfig kubeconfig-headless.yaml -o 'custom-columns=NAME:.metadata.name,REGION:.metadata.labels.topology\.kubernetes\.io/region,ZONE:.metadata.labels.topology\.kubernetes\.io/zone' -o json | jq -r '.items[].metadata.labels["topology.kubernetes.io/zone"]' | sort | uniq); do
    overrides="{ \"apiVersion\": \"v1\", \"spec\": { \"nodeSelector\": { \"topology.kubernetes.io/zone\": \"$zone\" } } }"
    kubectl run --kubeconfig kubeconfig-headless.yaml --timeout=5m -i --tty busybox --image=yauritux/busybox-curl --restart=Never  --overrides="$overrides" --rm --command -- curl http://ifconfig.me/ip >> temp_ips.txt 2>/dev/null
    done
    cat temp_ips.txt
    CLUSTER_IPS=$(awk '{gsub("pod \"busybox\" deleted", "", $0); print}' temp_ips.txt)
    rm temp_ips.txt
    
    echo $CLUSTER_IPS > cluster_ips.txt
    
    # https://stackoverflow.com/questions/40321035/remove-escape-sequence-characters-like-newline-tab-and-carriage-return-from-jso
    #
    IPS=$(echo $CLUSTER_IPS | jq -r -R '. | gsub("[ ]"; ", ") ')

    PostgreSQL='${self.input}'
    echo $(jq -r '.' <<< $PostgreSQL)
    echo $PostgreSQL | jq -r --arg ips "$IPS" '.spec.parameters |= . + { region: .region, allow_access: $ips }'

     )
   EOF
 }
}

output "egress_ips" {
  value = terraform_data.egress_ips.output
}


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
locals {
  remote_backend = one(data.terraform_remote_state.provider_context[*].outputs.provider_k8s)
  tfe_backend    = one(data.tfe_outputs.provider_context[*].values.provider_k8s)
//  tfe_backend    = one(data.tfe_outputs.provider_context[*].nonsensitive_values.provider_k8s)

  provider_k8s = local.remote_backend != null ? jsonencode(local.remote_backend) : jsonencode(local.tfe_backend)

}

resource "terraform_data" "provider_context" {
  depends_on = [terraform_data.kubectl_getnodes, terraform_data.argocd_bootstrap]

/*
  triggers_replace = {
    always_run = "${timestamp()}"
  }
*/

  triggers_replace = [
        terraform_data.kubectl_getnodes
  ]

 provisioner "local-exec" {
   interpreter = ["/bin/bash", "-c"]
   command = <<EOF
     (
    KUBECONFIG=kubeconfig-headless.yaml
    NAMESPACE=quovadis-btp
    set -e -o pipefail ;\
    TOKEN=${local.provider_k8s}
    echo | kubectl get nodes --kubeconfig $KUBECONFIG ;\
    kubectl create ns $NAMESPACE --kubeconfig $KUBECONFIG --dry-run=client -o yaml | kubectl apply --kubeconfig $KUBECONFIG -f -
    kubectl label namespace $NAMESPACE istio-injection=enabled --kubeconfig $KUBECONFIG

    INDEX=$(kubectl get -n kyma-system kyma default --kubeconfig $KUBECONFIG -o json | jq '.spec.modules | map(.name == "btp-operator") | index(true)' )
    echo $INDEX

    kubectl wait --for=jsonpath='{.status.modules[?(@.name=="api-gateway")].state}'=Ready kyma default -n kyma-system --timeout 5m --kubeconfig $KUBECONFIG
    while [ "$(kubectl --kubeconfig $KUBECONFIG -n kyma-system get deployment api-gateway-controller-manager --ignore-not-found)" = "" ]
    do 
      echo "deployments.apps - api-gateway-controller-manager - not found"
      sleep 1
    done
    echo | kubectl --kubeconfig $KUBECONFIG -n kyma-system rollout status deployment api-gateway-controller-manager --timeout 5m


    kubectl wait --for=jsonpath='{.status.modules[?(@.name=="btp-operator")].state}'=Ready kyma default -n kyma-system --timeout 5m --kubeconfig $KUBECONFIG
    while [ "$(kubectl --kubeconfig $KUBECONFIG -n kyma-system get deployment sap-btp-operator-controller-manager --ignore-not-found)" = "" ]
    do 
      echo "deployments.apps - sap-btp-operator-controller-manager - not found"
      sleep 1
    done
    echo | kubectl --kubeconfig $KUBECONFIG -n kyma-system rollout status deployment sap-btp-operator-controller-manager --timeout 5m

    SECRET=$(kubectl get secret sap-btp-service-operator -n kyma-system --kubeconfig $KUBECONFIG -o json )
    echo $SECRET
    CONFIG=$(echo $SECRET | jq --arg token "$TOKEN"  ' .data |= . + { "clientid": $token | fromjson | .clientid , "clientsecret": $token | fromjson | .clientsecret, "tokenurl": $token | fromjson | .tokenurl , "sm_url": $token | fromjson | .sm_url }' )
    echo $CONFIG
    echo $CONFIG | jq 'del(.metadata["namespace","creationTimestamp","resourceVersion","uid", "selfLink", "ownerReferences", "annotations", "labels"])' \
    | kubectl apply --kubeconfig $KUBECONFIG -n $NAMESPACE -f - 

     )
   EOF
 }
}

output "provider_context" {
  value = terraform_data.provider_context.output
}

# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs

data "kubernetes_nodes" "k8s_nodes" {
  depends_on = [
        btp_subaccount_environment_instance.kyma,
        terraform_data.kubectl_getnodes
  ]  
}

output "k8s_nodes" {
  value = { for node in data.kubernetes_nodes.k8s_nodes.nodes : node.metadata.0.name => node }
}

data "kubernetes_resources" "OpenIDConnect" {
  depends_on = [
        btp_subaccount_environment_instance.kyma,
        terraform_data.kubectl_getnodes
  ]  

  api_version    = "authentication.gardener.cloud/v1alpha1"
  kind           = "OpenIDConnect"
}

output "OpenIDConnect" {
  value = { for OpenIDConnect in data.kubernetes_resources.OpenIDConnect.objects : OpenIDConnect.metadata.name => OpenIDConnect.spec }
}

# https://gist.github.com/ptesny/2a6fce8d06a027f9e3b86967aeddf984
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/resource#object
#
data "kubernetes_resource" "KymaModules" {
  depends_on = [
        btp_subaccount_environment_instance.kyma,
        terraform_data.kubectl_getnodes
  ]  

  api_version    = "operator.kyma-project.io/v1beta2"
  kind           = "Kyma"

  metadata {
    name      = "default"
    namespace = "kyma-system"
  }  
} 

output "KymaModules" {
#  value = { for KymaModules in data.kubernetes_resource.KymaModules.object : KymaModules.metadata.name => KymaModules.status.modules }
  value =  data.kubernetes_resource.KymaModules.object.status.modules
}

data "kubernetes_resources" "ServiceInstance" {
  depends_on = [
        btp_subaccount_environment_instance.kyma,
        terraform_data.provider_context
  ]  

  api_version    = "services.cloud.sap.com/v1"
  kind           = "ServiceInstance"
}

output "ServiceInstance" {
#  value = { for ServiceInstance in data.kubernetes_resources.ServiceInstance.objects : ServiceInstance.metadata.name => ServiceInstance.spec }
 value = "kubectl get serviceinstances -A --kubeconfig kubeconfig_bot_exec.yaml"
}
