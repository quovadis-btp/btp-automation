# https://developer.hashicorp.com/terraform/language/settings/backends/kubernetes
# https://developer.hashicorp.com/terraform/language/state/remote-state-data#the-terraform_remote_state-data-source
# https://opentofu.org/docs/intro/install/standalone/
#
terraform {
  backend "kubernetes" {
    secret_suffix = "state-89982f73trial"
    config_path   = "~/.kube/kubeconfig--c-4860efd-default.yaml"
    namespace     = "tf-runtime-context"
  }
}