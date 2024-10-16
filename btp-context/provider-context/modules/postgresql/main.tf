data "btp_globalaccount" "this" {}

data "btp_globalaccount_entitlements" "all" {}




# look up all available subaccounts of a global acount that have a specific label attached
data "btp_subaccounts" "filtered" {
  labels_filter = "btp-provider="
}

data "btp_subaccount" "context" {
  id = var.subaccount_id != "" ? var.subaccount_id : data.btp_subaccounts.filtered.values.id
}


locals {
  
  free_entitlements = { 
    for service in data.btp_globalaccount_entitlements.all.values : service.service_name => service if service.category == "SERVICE" && service.plan_name == "free"
  }
}

output "free_entitlements" {
  value = local.free_entitlements
}


# Extract the right entry from all entitlements
locals {

  postgresql_db = {
    for service in data.btp_globalaccount_entitlements.all.values : service.service_name => service if service.category == "SERVICE" && service.plan_name == "trial" && service.service_name == "postgresql-db"
  }

  postgresql_standard_plan = {
    for service in data.btp_globalaccount_entitlements.all.values : service.service_name => service if service.category == "SERVICE" && service.plan_name == "standard" && service.service_name == "postgresql-db"
  }

}

// only use the trial postresql plan, the reson being even the free postfresql plan incurs a charge
#
output "postgresql_db" {
  value       = local.postgresql_db
}


# adding postgresql-db entitlement (quota-based)
#
resource "btp_subaccount_entitlement" "postgresql" {
  count          = var.BTP_POSTGRESQL_PLAN != "trial" ? 0 : 1

  subaccount_id = data.btp_subaccount.context.id
  service_name  = "postgresql-db"
  plan_name     = "trial"
  amount        = 1
}

# look up all service bindings of a given subaccount
#
data "btp_subaccount_service_bindings" "all" {
  subaccount_id = data.btp_subaccount.context.id
}

locals {
  has_postgresql_binding = {
    for binding in data.btp_subaccount_service_bindings.all.values : binding.name => binding if binding.name == "postgresql-binding"
  }
}

data "btp_subaccount_service_binding" "postgresql" {

//  count          = var.BTP_POSTGRESQL_PLAN != "trial" ? 0 : 1
  count          =  local.has_postgresql_binding == {} ? 0 : 1
//  count          =  var.HAS_POSTGRESQL_BINDING ? 1 : 0


  subaccount_id = data.btp_subaccount.context.id
  name          = "postgresql-binding"  
}

locals {
  credentials            = one(data.btp_subaccount_service_binding.postgresql[*].credentials)
  postgresql-credentials = local.credentials != null ? jsondecode(local.credentials) : null
}

output "postgresql-binding" {
  value = nonsensitive( local.postgresql-credentials )
}
