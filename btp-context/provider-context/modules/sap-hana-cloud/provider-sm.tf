
resource "btp_subaccount_entitlement" "sm" {
  subaccount_id = data.btp_subaccount.context.id
  service_name  = "service-manager"
  plan_name     = "service-operator-access"
}

data "btp_subaccount_service_plan" "sm" {
  depends_on     = [btp_subaccount_entitlement.sm]

  subaccount_id = data.btp_subaccount.context.id
  offering_name = "service-manager"
  name          = "service-operator-access"
}


resource "btp_subaccount_service_instance" "provider-k8s" {
  depends_on     = [btp_subaccount_entitlement.sm]

  subaccount_id  = data.btp_subaccount.context.id
  name           = "provider-k8s"
  serviceplan_id = data.btp_subaccount_service_plan.sm.id

  parameters     = jsonencode({
      "grantType": "clientCredentials"
  })
}

resource "btp_subaccount_service_binding" "provider_sm" {
  depends_on          = [btp_subaccount_service_instance.provider-k8s]
  
  subaccount_id       = data.btp_subaccount.context.id
  service_instance_id = btp_subaccount_service_instance.provider-k8s.id
  name                = "provider-sm-binding"
}


locals {
  provider_credentials = jsondecode(btp_subaccount_service_binding.provider_sm.credentials)
}

resource "local_sensitive_file" "provider_sm" {
  content = jsonencode({
    clientid       = base64encode(local.provider_credentials.clientid)
    clientsecret   = base64encode(local.provider_credentials.clientsecret)
    sm_url         = base64encode(local.provider_credentials.sm_url)
    tokenurl       = base64encode(local.provider_credentials.url)
    tokenurlsuffix = base64encode("/oauth/token")
  })
  filename = "provider_sm.json"
}

/*
resource "local_file" "provider_sm" {
  content  = <<EOT
clientid=${local.provider_credentials.clientid}
clientsecret=${local.provider_credentials.clientsecret}
sm_url=${local.provider_credentials.sm_url}
tokenurl=${local.provider_credentials.url}
tokenurlsuffix=/oauth/token
EOT
  filename = "provider-sm-decoded.env"
}
*/
