terraform {
  required_providers {
    btp = {
      source  = "SAP/btp"
      version = "1.5.0"
    }
    jq = {
      source  = "massdriver-cloud/jq"
    }
    http-full = {
      source = "salrashid123/http-full"
    }        
  }
}

provider "jq" {}
provider "http-full" {}

provider "btp" {
  globalaccount  = var.BTP_GLOBAL_ACCOUNT
  cli_server_url = var.BTP_BACKEND_URL
  username       = var.BTP_BOT_USER
  password       = var.BTP_BOT_PASSWORD
  idp            = var.BTP_CUSTOM_IDP
}
