output "sap_hana_cloud_central" {
  value = module.sap_hana_cloud.sap_hana_cloud_central
}


output "dbadmin_credentials" {
  sensitive = true
  value = jsondecode(module.sap_hana_cloud.dbadmin_credentials)
}


output "hc_credentials" {
  sensitive = true
  value = jsondecode(module.sap_hana_cloud.hc_credentials)
}

output "hc_credentials_x509" {
  sensitive = true
  value = jsondecode(module.sap_hana_cloud.hc_credentials_x509)
}

output "dest_credentials" {
  sensitive = true
  value = jsondecode(module.sap_hana_cloud.dest_credentials)
}