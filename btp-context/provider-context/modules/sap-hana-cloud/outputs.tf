output "sap_hana_cloud_central" {
  value = data.btp_subaccount_subscription.hana_cloud_tools_data.subscription_url
}


output "dbadmin_credentials" {
  value = btp_subaccount_service_binding.hc_binding_dbadmin.credentials
}

output "hc_credentials" {
  value = btp_subaccount_service_binding.hc_binding.credentials
}

output "hc_credentials_x509" {
  value = btp_subaccount_service_binding.hc_binding_x509.credentials
}

output "dest_credentials" {
  value = btp_subaccount_service_binding.dest_binding.credentials
}
