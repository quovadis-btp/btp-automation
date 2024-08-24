terraform {
  required_providers {
    btp = {
      source  = "SAP/btp"
      version = "~>1.5.0"
    }
  }
}

# https://kubernetes.io/docs/concepts/architecture/leases/
# https://kubernetes.io/docs/concepts/security/multi-tenancy/
#
/*
# rbac role rules for the tf-runner kuebconfig user / sa
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  - secrets # needs to be added
  verbs:
  - '*'
# and leases needs to be added
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  verbs:
  - '*'
*/

/*
terraform {
  backend "kubernetes" {
    secret_suffix = "custom-idp-state-2392906ftrial"
    config_path   = "~/.kube/argocdaas-eu12.yaml"
    namespace     = "sf-213a7545-adb5-4737-b489-5f8a6264fb6e"
  }
}
*/

terraform {
  backend "kubernetes" {
    secret_suffix = "state-2392906ftrial"
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