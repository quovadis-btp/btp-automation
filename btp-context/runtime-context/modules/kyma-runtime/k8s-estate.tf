/*
.PHONY: get-cluster-zones
get-cluster-zones: ## get cluster nodes topology
  kubectl get nodes -o custom-columns=NAME:.metadata.name,REGION:".metadata.labels.topology\.kubernetes\.io/region",ZONE:".metadata.labels.topology\.kubernetes\.io/zone" --kubeconfig $(KUBECONFIG)

.PHONY: get-cluster-id
get-cluster-id: ## get cluster id for hanacloud instance mapping
  kubectl get cm sap-btp-operator-config -n kyma-system --kubeconfig $(KUBECONFIG) -o jsonpath='{.data.CLUSTER_ID}'

CLUSTER_DOMAIN= $(shell kubectl get cm -n kube-system shoot-info --kubeconfig $(KUBECONFIG) -ojsonpath='{.data.domain}' )
ISTIO_GATEWAY=kyma-gateway.kyma-system.svc.cluster.local
*/


# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs

data "kubernetes_config_map_v1" "sap-btp-operator-config" {
  depends_on = [
        terraform_data.kubectl_getnodes
  ]  

  metadata {
    name = "sap-btp-operator-config"
    namespace = "kyma-system"
  }
}

output "sap-btp-operator-config" {
  value =  jsondecode(jsonencode(data.kubernetes_config_map_v1.sap-btp-operator-config.data))
}


data "kubernetes_config_map_v1" "shoot_info" {
  depends_on = [
        terraform_data.kubectl_getnodes
  ]  

  metadata {
    name = "shoot-info"
    namespace = "kube-system"
  }
}

output "shoot_info" {
  value =  data.kubernetes_config_map_v1.shoot_info.data
}



data "kubernetes_nodes" "k8s_nodes" {
  depends_on = [
        terraform_data.kubectl_getnodes
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
        terraform_data.provider_context
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
        terraform_data.provider_context
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