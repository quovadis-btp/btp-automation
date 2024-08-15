
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
          channel = "fast"
        },
        {
          name    = "istio"
          channel = "fast"
        },
        {
          name    = "btp-operator"
          channel = "fast"
        },
        {
            "name": "serverless",
            "channel": "regular"
        },
        {
            "name": "connectivity-proxy",
            "channel": "regular"
        }
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
    create = "30m"
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