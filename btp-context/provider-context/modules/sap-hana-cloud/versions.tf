terraform {
  required_version = ">= 1.9"

  required_providers {
    btp = {
      source  = "SAP/btp"
    }
    http-full = {
      source = "salrashid123/http-full"
    }       
  }
}