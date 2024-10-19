// https://discuss.hashicorp.com/t/extracting-variables-from-workspace-name-in-tfc/55952/4
//
locals {
  workspace_name = "${terraform.workspace}"
}

output "workspace_name" {
  value = local.workspace_name
}

data "tfe_outputs" "current-runtime-context" {
  organization = var.provider_context_organization
  workspace    = "${terraform.workspace}"
}

output "user_plan" {
  value = nonsensitive(data.tfe_outputs.current-runtime-context.values.user_plan)
}

output "user_apply" {
  value = nonsensitive(data.tfe_outputs.current-runtime-context.values.user_apply)
}

# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs

data "kubernetes_config_map_v1" "sap-btp-operator-config" {
  depends_on = [
        terraform_data.provider_context

  ]  

  metadata {
    name = "sap-btp-operator-config"
    namespace = "kyma-system"
  }
}

locals {
  cluster_id = jsondecode(jsonencode(data.kubernetes_config_map_v1.sap-btp-operator-config.data)).CLUSTER_ID
}

output "cluster_id" {
  value = local.cluster_id
}

output "sap-btp-operator-config" {
  value =  jsondecode(jsonencode(data.kubernetes_config_map_v1.sap-btp-operator-config.data))
}


data "kubernetes_config_map_v1" "shoot_info" {
  depends_on = [
        //terraform_data.kubectl_getnodes
        terraform_data.provider_context
  ]  

  metadata {
    name = "shoot-info"
    namespace = "kube-system"
  }
}

output "shoot_info" {
  value =  jsondecode(jsonencode(data.kubernetes_config_map_v1.shoot_info.data))
}



data "kubernetes_nodes" "k8s_nodes" {
  depends_on = [
        //terraform_data.kubectl_getnodes
        terraform_data.provider_context
  ]  
}

locals {
  k8s_nodes = { for node in data.kubernetes_nodes.k8s_nodes.nodes : node.metadata.0.name => node }
}

# https://registry.terraform.io/providers/massdriver-cloud/jq/latest/docs/data-sources/query
#
data "jq_query" "k8s_nodes" {
  depends_on = [
        data.kubernetes_nodes.k8s_nodes
  ] 
  data =  jsonencode(local.k8s_nodes)
  query = "[ .[].metadata[] | { NAME: .name, ZONE: .labels.\"topology.kubernetes.io/zone\", REGION: .labels.\"topology.kubernetes.io/region\" } ]"
}

# https://registry.terraform.io/providers/massdriver-cloud/jq/latest/docs/data-sources/query#multiple-results
#
output "k8s_zones" { 
// multi-line strings cannot be converted to HCL with jsondecode
/*
<<EOT
{"NAME":"shoot--kyma-stage--c-667f002-cpu-worker-0-z1-7598b-***","REGION":"eu-de-1","ZONE":"eu-de-1d"}
{"NAME":"shoot--kyma-stage--c-667f002-cpu-worker-0-z2-84f4f-***","REGION":"eu-de-1","ZONE":"eu-de-1b"}
{"NAME":"shoot--kyma-stage--c-667f002-cpu-worker-0-z3-84958-***","REGION":"eu-de-1","ZONE":"eu-de-1a"}
EOT
*/
  value = jsondecode(data.jq_query.k8s_nodes.result)
}

output "k8s_zones_json" {
  value = data.jq_query.k8s_nodes.result
}

# https://registry.terraform.io/providers/massdriver-cloud/jq/latest/docs/data-sources/query#hcl-compatibility
#
output "k8s_nodes" { 
  value = jsondecode(jsonencode(local.k8s_nodes))
}

output "k8s_nodes_json" {
  value = jsonencode(local.k8s_nodes)
}

output "k8s_nodes_raw" {
  value = local.k8s_nodes
}

# https://www.hashicorp.com/blog/wait-conditions-in-the-kubernetes-provider-for-hashicorp-terraform
#
data "kubernetes_resources" "OpenIDConnect" {
  depends_on = [
        terraform_data.bootstrap-kymaruntime-bot
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
        terraform_data.bootstrap-kymaruntime-bot

  ]  

  api_version    = "operator.kyma-project.io/v1beta2"
  kind           = "Kyma"

  metadata {
    name      = "default"
    namespace = "kyma-system"
  }  
} 

locals {
#  value = { for KymaModules in data.kubernetes_resource.KymaModules.object : KymaModules.metadata.name => KymaModules.status.modules }
  KymaModules = data.kubernetes_resource.KymaModules.object.status.modules
}

data "jq_query" "KymaModules" {
  depends_on = [
        data.kubernetes_resource.KymaModules
  ] 
  data =  jsonencode(local.KymaModules)
  query = "[ .[] | { channel, name, version, state, api: .resource.apiVersion, fqdn } ]"
}


output "KymaModules" {
  value =  jsondecode(data.jq_query.KymaModules.result)
}

output "KymaModules_json" {
  value =  jsonencode(local.KymaModules)
}

output "KymaModules_raw" {
  value =  local.KymaModules
}

# https://github.com/hashicorp/terraform-provider-kubernetes/issues/1583
# https://medium.com/@danieljimgarcia/dont-use-the-terraform-kubernetes-manifest-resource-6c7ff4fe629a
# https://discuss.hashicorp.com/t/how-to-put-a-condition-on-a-for-each/55499/2
# https://stackoverflow.com/questions/77119996/how-to-make-terraform-ignore-a-resource-if-another-one-is-not-deployed
#

/*
data "kubernetes_resources" "ServiceInstance" {
  depends_on = [
        terraform_data.bootstrap-kymaruntime-bot
  ]  

  api_version    = "services.cloud.sap.com/v1"
  kind           = "ServiceInstance"
}

output "ServiceInstance" {
 value = data.kubernetes_resources.ServiceInstance.objects
 #value = { for ServiceInstance in data.kubernetes_resources.ServiceInstance.objects : ServiceInstance.metadata.name => ServiceInstance.spec }
 #value = "kubectl get serviceinstances -A --kubeconfig kubeconfig_bot_exec.yaml"
}
*/

// kubectl -n istio-system get svc istio-ingressgateway
//
data "kubernetes_service_v1" "Ingress_LoadBalancer" {
  depends_on = [
        terraform_data.bootstrap-kymaruntime-bot
  ]  

  metadata {
    name = "istio-ingressgateway"
    namespace = "istio-system"
  }
}

// kubectl -n istio-system get svc istio-ingressgateway  --kubeconfig kubeconfig_prod_exec.yaml -o json | jq '.status'
//
/*
{
  "loadBalancer": {
    "ingress": [
      {
        "hostname": "a6f2a621efb344d4ebf6f010952246de-1219680835.us-east-1.elb.amazonaws.com"
      }
    ]
  }
}
*/
output "Ingress_LoadBalancer" {
  //value = [data.kubernetes_service_v1.Ingress_LoadBalancer.status.0.load_balancer.0.ingress.0.hostname]
  //value = [data.kubernetes_service_v1.Ingress_LoadBalancer.status.0.load_balancer.0.ingress.0.ip]
  value = data.kubernetes_service_v1.Ingress_LoadBalancer.status.0.load_balancer.0.ingress

}

#---------------
/* */

 # this should be put in a separate terraform configuration

resource "kubernetes_cluster_role_binding_v1" "quovadis-btp" {
  depends_on = [
        terraform_data.bootstrap-kymaruntime-bot
  ]  

  metadata {
    name = "quovadis-btp"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "quovadis-btp"
  }
  lifecycle {
    ignore_changes = all
  }  
}

resource "kubernetes_default_service_account_v1" "quovadis-btp" {
  depends_on = [
        terraform_data.bootstrap-kymaruntime-bot,
        kubernetes_secret_v1.quovadis-btp
  ]  

  metadata {
    namespace = "quovadis-btp"
  }
  secret {
    name = "${kubernetes_secret_v1.quovadis-btp.metadata.0.name}"
  }
  automount_service_account_token = false  
  lifecycle {
    ignore_changes = all
  }  
}

resource "kubernetes_secret_v1" "quovadis-btp" {
  depends_on = [
        terraform_data.bootstrap-kymaruntime-bot
  ]  

  metadata {
    annotations = {
      "kubernetes.io/service-account.name" = "default"
    }
    name = "quovadis-btp-token-sa"
    namespace = "quovadis-btp"
  }
  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true  

  lifecycle {
    ignore_changes = all
  }  
}

/*
https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/kubernetes-configuration#configure-an-oidc-identity-provider

The OIDC identity resolves authentication to the Kubernetes API, but it first requires authorization to interact with that API. 
So, you must bind RBAC roles to the OIDC identity in Kubernetes.

You can use both "User" and "Group" subjects in your role bindings. 
*/

# https://developer.hashicorp.com/terraform/tutorials/cloud/dynamic-credentials
#
resource "kubernetes_cluster_role_binding_v1" "oidc_role" {
  depends_on = [ 
      //terraform_data.bootstrap-tcf-oidc
      terraform_data.bootstrap-kymaruntime-bot
      ] 

  metadata {
    name = "terraform-identity-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = var.provider_context_organization //"${local.organization_name}"
    namespace = ""
  }
/*
  lifecycle {
    ignore_changes = all
  } */   
}