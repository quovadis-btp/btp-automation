terraform {
  backend "kubernetes" {
    secret_suffix = "state-2392906ftrial"
    config_path   = "~/.kube/kubeconfig--c-4860efd-default.yaml"
    namespace     = "tf-runtime-context"
  }
}