# https://developer.hashicorp.com/terraform/language/modules/develop/providers#implicit-provider-inheritance
# https://developer.hashicorp.com/terraform/language/modules/develop/composition
#
terraform {
  required_providers {
    btp = {
      source  = "SAP/btp"
      version = "~> 1.7.0"
    }
    jq = {
      source  = "massdriver-cloud/jq"
    }
    http-full = {
      source = "salrashid123/http-full"
      version = "1.3.1"
    }        
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }  
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }  
    argocd = {
      source = "argoproj-labs/argocd"
      version = "~> 7.0.3"      
    } 
    github = {
      source  = "integrations/github"
      version = "~> 6.3.1"
    }
  }
}