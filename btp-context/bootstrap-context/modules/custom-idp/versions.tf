terraform {
  required_version = ">= 1.9.3"

  required_providers {
    btp = {
      source  = "SAP/btp"
      version = "~>1.7.0"
    }
  }
}