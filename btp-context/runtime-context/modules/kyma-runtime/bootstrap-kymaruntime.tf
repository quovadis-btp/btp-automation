
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


resource "btp_subaccount_environment_instance" "kyma" {
  count            = var.BTP_KYMA_DRY_RUN ? 0 : 1
  depends_on       = [btp_subaccount_service_binding.ias-local-binding, btp_subaccount_service_binding.ias-local-binding-secret, btp_subaccount_service_binding.ias-local-binding-cert, btp_subaccount_entitlement.connectivity]

  subaccount_id    = data.btp_subaccount.context.id
  name             = "${var.BTP_SUBACCOUNT}-kyma"
  environment_type = "kyma"
  service_name     = btp_subaccount_entitlement.kymaruntime.service_name
  plan_name        = btp_subaccount_entitlement.kymaruntime.plan_name
  parameters = jsonencode({
    modules = {
      list = [
        {
          name    = "api-gateway"
          channel = "regular"
        },
        {
          name    = "istio"
          channel = "regular"
        },
        {
          name    = "btp-operator"
          channel = "regular"
        },
        {
            "name": "serverless",
            "channel": "regular"
        }
        /*
        ,
        {
            "name": "connectivity-proxy",
            "channel": "regular"
        },
        {
            "name": "cloud-manager",
            "channel": "regular"
        }
        */
      ]
    }
    oidc = {
      groupsClaim    = "groups"
      signingAlgs    = ["RS256"]
      usernameClaim  = "sub"
      usernamePrefix = "-"
      clientID       = jsondecode(btp_subaccount_service_binding.ias-local-binding.credentials).clientid
      issuerURL      = jsondecode(btp_subaccount_service_binding.ias-local-binding.credentials).url
    }
    name   = "${var.BTP_SUBACCOUNT}-kyma"
    region = var.BTP_KYMA_PLAN != "trial" ? var.BTP_KYMA_REGION : ""
    administrators = var.cluster_admins
  })
  timeouts = {
    create = "40m"
    update = "30m"
    delete = "60m"
  }
}

# https://stackoverflow.com/a/74460150
locals {
  labels = one(btp_subaccount_environment_instance.kyma[*].labels)
}

data "http" "kubeconfig" {
  #url = jsondecode(btp_subaccount_environment_instance.kyma[0].labels)["KubeconfigURL"]
  url = local.labels != null ? jsondecode(local.labels)["KubeconfigURL"] : "https://sap.com"
}

resource "local_sensitive_file" "kubeconfig-oidc" {
  #filename = ".${data.btp_subaccount.context.id}-${var.BTP_KYMA_NAME}.kubeconfig"
  filename = "kubeconfig-oidc.json"
  content  = jsonencode(yamldecode(data.http.kubeconfig.response_body))
}

resource "local_file" "kubeconfig_url" {
  depends_on = [btp_subaccount_environment_instance.kyma[0]]
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
    data = jsonencode(yamldecode(data.http.kubeconfig.response_body))
    #query = "del(.users[] | .user | .exec)"
    query = "del(.users[] | .user | .exec) | .users[] |= . + { user: { token: ${local.id_token} } }"
}

output "kubeconfig" {
  value = jsondecode(data.jq_query.kubeconfig.result)
}

resource "local_sensitive_file" "kubeconfig-headless" {
  filename = "kubeconfig-headless.json"
  content  = data.jq_query.kubeconfig.result
}

resource "local_sensitive_file" "kubeconfig-yaml" {
  filename = "kubeconfig.yaml"
  content  = yamlencode(jsondecode(data.jq_query.kubeconfig.result) )
}

# headless kubeconfig
locals {
  kubeconfig  = yamlencode(jsondecode(data.jq_query.kubeconfig.result) )
}

# https://spacelift.io/blog/terraform-yaml#what-is-the-yamldecode-function-in-terraform
#
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


# kubectl config view --minify --raw  --kubeconfig <(echo ${local.kubeconfig})  > kubeconfig2.yaml ;\
#      kubectl config view --minify --raw  --kubeconfig <(echo $data.jq_query.kubeconfig.result})  > kubeconfig2.yaml ;\
#     echo ${data.jq_query.kubeconfig.result} > kubeconfig2.yaml ;\
 

# https://stackoverflow.com/questions/72607500/how-to-handle-multiple-lines-within-a-command-block-in-terraform
# https://stackoverflow.com/questions/57041699/how-to-use-bash-commands-in-terraform-template-file-variables
# https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external
#
resource "null_resource" "kubectl_getnodes" {
  triggers = {
    always_run = "${timestamp()}"
  }
 provisioner "local-exec" {
   interpreter = ["/bin/bash", "-c"]
   command = <<EOF
     (
     set -e -o pipefail ;\
     echo "${local.kubeconfig}" > kubeconfig-headless2.yaml ;\
     echo | kubectl get nodes --kubeconfig kubeconfig-headless2.yaml ;\
     )
   EOF
 }
}

resource "terraform_data" "kubectl_getnodes" {
  triggers_replace = {
    always_run = "${timestamp()}"
  }
 provisioner "local-exec" {
   interpreter = ["/bin/bash", "-c"]
   command = <<EOF
     (
    set -e -o pipefail ;\
    echo "${local.kubeconfig}" > kubeconfig-headless.yaml ;\
    echo | kubectl get nodes --kubeconfig kubeconfig-headless.yaml ;\
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
  request_body = "grant_type=password&username=${var.argocd_username}&password=${var.argocd_password}&client_id=${var.argocd_clientid}&scope=groups,email"
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

resource "terraform_data" "egress_ips" {

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
    set -e -o pipefail ;\
    for zone in $(kubectl get nodes --kubeconfig kubeconfig-headless.yaml -o 'custom-columns=NAME:.metadata.name,REGION:.metadata.labels.topology\.kubernetes\.io/region,ZONE:.metadata.labels.topology\.kubernetes\.io/zone' -o json | jq -r '.items[].metadata.labels["topology.kubernetes.io/zone"]' | sort | uniq); do
    overrides="{ \"apiVersion\": \"v1\", \"spec\": { \"nodeSelector\": { \"topology.kubernetes.io/zone\": \"$zone\" } } }"
    kubectl run --kubeconfig kubeconfig-headless.yaml -i --tty busybox --image=yauritux/busybox-curl --restart=Never  --overrides="$overrides" --rm --command -- curl http://ifconfig.me/ip >>/tmp/cluster_ips 2>/dev/null
    done
    cat /tmp/cluster_ips
    awk '{gsub("pod \"busybox\" deleted", "", $0); print}' /tmp/cluster_ips
    rm /tmp/cluster_ips
     )
   EOF
 }
}

# https://developer.hashicorp.com/terraform/language/state/remote-state-data#the-terraform_remote_state-data-source
#
data "terraform_remote_state" "provider_context" {
  backend = "kubernetes"
  config = {
    secret_suffix    = "state-89982f73trial"
    config_path      = "~/.kube/kubeconfig--c-4860efd-default.yaml"    
    namespace        = "tf-provider-context"
    load_config_file = true
  }
}

/*
resource "provider_context" "provider_k8s" {
  provider_k8s = "${data.terraform_remote_state.provider_context.outputs.provider_k8s}"

}*/

locals {
  provider_k8s = jsonencode(data.terraform_remote_state.provider_context.outputs.provider_k8s)

}

resource "terraform_data" "provider_context" {
/*
  triggers_replace = {
    always_run = "${timestamp()}"
  }
*/

  triggers_replace = [
        terraform_data.kubectl_getnodes
  ]
/*
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
    kubectl get secret sap-btp-service-operator -n kyma-system --kubeconfig $KUBECONFIG -o json > btp-service-operator-kyma.json
    CONFIG=$(cat btp-service-operator-kyma.json | jq --arg token "$TOKEN"  ' .data |= . + { "clientid": $token | fromjson | .clientid , "clientsecret": $token | fromjson | .clientsecret, "tokenurl": $token | fromjson | .tokenurl , "sm_url": $token | fromjson | .sm_url }' )
    echo $CONFIG
    echo $CONFIG | jq 'del(.metadata["namespace","creationTimestamp","resourceVersion","uid", "selfLink", "ownerReferences", "annotations", "labels"])' \
    | kubectl apply --kubeconfig $KUBECONFIG -n $NAMESPACE -f - 

     )
   EOF
 }

*/


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
