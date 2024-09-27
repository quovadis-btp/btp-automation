# https://developer.hashicorp.com/terraform/language/modules/develop/providers#implicit-provider-inheritance
# https://developer.hashicorp.com/terraform/language/modules/develop/composition
#
terraform {
  required_providers {
    btp = {
      source  = "SAP/btp"
    }
    jq = {
      source  = "massdriver-cloud/jq"
    }
    http-full = {
      source = "salrashid123/http-full"
    }        
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }  
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }  

  }
}