terraform {
  required_version = ">= 1.9"

  required_providers {
    btp = {
      source  = "SAP/btp"
      version = ">= 1.6.0"
    }
  }
}