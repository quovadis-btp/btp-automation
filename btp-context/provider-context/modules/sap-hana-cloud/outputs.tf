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

output "provider_k8s" {
  value = local_sensitive_file.provider_sm
}

# provider-context (subaccount) data collection

# We output the data that we need in order to import the resources in the next step.
output "subaccount_name" {
  description = "The name of the subaccount."
  value       = data.btp_subaccount.context.name
}

output "subaccount_region" {
  description = "The region of the subaccount."
  value       = data.btp_subaccount.context.region
}

output "subaccount_subdomain" {
  description = "The subdomain of the subaccount."
  value       = data.btp_subaccount.context.subdomain
}

output "subaccount_usage" {
  description = "The usage of the subaccount."
  value       = data.btp_subaccount.context.usage
}

output "subaccount_labels" {
  description = "The labels of the subaccount."
  value       = data.btp_subaccount.context.labels
}

output "postgresql_db" {
  value       = local.postgresql_db
}

output "launchpad_free" {
  value       = local.launchpad_free
}
