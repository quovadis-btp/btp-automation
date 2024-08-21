terraform {
  required_providers {
    btp = {
      source  = "SAP/btp"
      version = "~>1.5.0"
    }
  }
}

terraform {
  backend "kubernetes" {
    secret_suffix = "state-89982f73trial"
    config_path   = "~/.kube/kubeconfig--c-4860efd-default.yaml"
    namespace     = "tf-bootstrap-context"
  }
}


provider "btp" {
  globalaccount = var.globalaccount
  username      = var.username
  password      = var.password
  idp           = var.idp
}