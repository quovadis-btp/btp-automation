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
  value =  { for shoot in data.kubernetes_config_map_v1.shoot_info : shoot.id => shoot.data }
//  value =  data.kubernetes_config_map_v1.shoot_info.data
}

data "kubernetes_nodes" "k8s_nodes" {
  depends_on = [
        terraform_data.kubectl_getnodes
  ]  
}

output "k8s_nodes" {
  value = { for node in data.kubernetes_nodes.k8s_nodes.nodes : node.metadata.0.name => node }
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

output "KymaModules" {
#  value = { for KymaModules in data.kubernetes_resource.KymaModules.object : KymaModules.metadata.name => KymaModules.status.modules }
  value =  data.kubernetes_resource.KymaModules.object.status.modules
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