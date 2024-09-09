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

output "provider_k8s" {
  sensitive = true
  value = module.provider_context.provider_k8s["content"]
}

output "postgresql_db" {
  value       = module.provider_context.postgresql_db
}

output "launchpad_free" {
  value       = module.provider_context.launchpad_free
}

output "free_entitlements" {
  value = module.provider_context.free_entitlements
}

output "sap_build_workzone_subscription_url" {
  value       = module.provider_context.sap_build_workzone_subscription_url
  description = "SAP Build Workzone subscription URL."
}


output "httpbin_headers_url" {
  value       = module.provider_context.httpbin_headers_url
  description = "HTTPBIN headers."
}

output "provisioning_service_environments_url" {
  value       = module.provider_context.provisioning_service_environments_url
  description = "SAP Cloud Management Service APIs (provisioning_service_url)."
}
