output "sap_hana_cloud_central" {
  value = module.provider_context.sap_hana_cloud_central
}


output "dbadmin_credentials" {
  sensitive = true
  value = jsondecode(module.provider_context.dbadmin_credentials)
}


output "hc_credentials" {
  sensitive = true
  value = jsondecode(module.provider_context.hc_credentials)
}

output "hc_credentials_x509" {
  sensitive = true
  value = jsondecode(module.provider_context.hc_credentials_x509)
}

output "dest_credentials" {
  sensitive = true
  value = jsondecode(module.provider_context.dest_credentials)
}