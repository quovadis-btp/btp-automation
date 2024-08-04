terraform {
  required_version = ">= 1.8"

  required_providers {
    btp = {
      source  = "SAP/btp"
      version = ">= 1.5.0"
    }
  }
}