terraform {
  backend "kubernetes" {
    secret_suffix = "state-89982f73trial"
    config_path   = "~/.kube/kubeconfig--c-4860efd-default.yaml"
    namespace     = "tf-runtime-context"
  }
}