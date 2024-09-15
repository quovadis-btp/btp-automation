terraform {
  required_providers {
    btp = {
      source  = "SAP/btp"
      version = "~>1.6.0"
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
  }
}