#------------------------------------------------------------------------------------------------------
# BOT OIDC application 
# ------------------------------------------------------------------------------------------------------

resource "btp_subaccount_service_instance" "quovadis-ias-bot" {
  depends_on     = [btp_subaccount_trust_configuration.custom_idp]

  subaccount_id  = data.btp_subaccount.context.id
  name           = "ias-bot"
  serviceplan_id = data.btp_subaccount_service_plan.identity_application.id

  parameters = jsonencode({
        
        "name": "kyma-bot-${data.btp_subaccount.context.id}",
        "display-name": "kyma-bot",
        
        "user-access": "public",
        "oauth2-configuration": {
            "grant-types": [
                "authorization_code",
                "authorization_code_pkce_s256",
                "password",
                "refresh_token"
            ],
            "token-policy": {
                "token-validity": 3600,
                "refresh-validity": 15552000,
                "refresh-usage-after-renewal": "off",
                "refresh-parallel": 3,
                "access-token-format": "default"
            },
            "public-client": true,
            "redirect-uris": [
                "https://dashboard.kyma.cloud.sap",
                "https://dashboard.dev.kyma.cloud.sap",
                "https://dashboard.stage.kyma.cloud.sap",
                "http://localhost:8000"
            ]
        },
        "subject-name-identifier": {
            "attribute": "mail",
            "fallback-attribute": "none"
        },
        "default-attributes": null,
        "assertion-attributes": {
            "email": "mail",
            "groups": "companyGroups",
            "first_name": "firstName",
            "last_name": "lastName",
            "login_name": "loginName",
            "mail": "mail",
            "scope": "companyGroups",
            "user_uuid": "userUuid",
            "locale": "language"
        }
  }) 
}


resource "btp_subaccount_service_binding" "ias-bot-binding" {
  depends_on          = [btp_subaccount_service_instance.quovadis-ias-bot]

  subaccount_id       = data.btp_subaccount.context.id
  name                = "ias-bot-binding"
  service_instance_id = btp_subaccount_service_instance.quovadis-ias-bot.id
  parameters = jsonencode({
    credential-type = "NONE"
  })
}

locals {
  bot = jsondecode(btp_subaccount_service_binding.ias-bot-binding.credentials)
}

resource "local_sensitive_file" "bot" {
  content = jsonencode({
    clientid = local.bot.clientid
    url      = local.bot.url
  })
  filename = "bot.json"
}

resource "btp_subaccount_service_binding" "ias-bot-binding-cert" {
  depends_on          = [btp_subaccount_service_instance.quovadis-ias-bot]

  subaccount_id       = data.btp_subaccount.context.id
  name                = "ias-bot-binding-cert"
  service_instance_id = btp_subaccount_service_instance.quovadis-ias-bot.id
  parameters = jsonencode({
    credential-type = "X509_GENERATED"
    key-length      = 4096
    validity        = 1
    validity-type   = "DAYS"
    app-identifier  = "kymaruntime"
  })
}

locals {
  bot-cert = jsondecode(btp_subaccount_service_binding.ias-bot-binding-cert.credentials)
}

resource "local_sensitive_file" "bot-cert" {
  content = jsonencode({
    clientid = local.bot-cert.clientid
    url      = local.bot-cert.url
  })
  filename = "bot-cert.json"
}

resource "btp_subaccount_service_binding" "ias-bot-binding-secret" {
  depends_on          = [btp_subaccount_service_instance.quovadis-ias-bot]

  subaccount_id       = data.btp_subaccount.context.id
  name                = "ias-bot-binding-secret"
  service_instance_id = btp_subaccount_service_instance.quovadis-ias-bot.id
  parameters = jsonencode({
    credential-type = "SECRET"
  })
}

locals {
  bot-secret = jsondecode(btp_subaccount_service_binding.ias-bot-binding-secret.credentials)
}

resource "local_sensitive_file" "bot-secret" {
  content = jsonencode({
    clientid = local.bot-secret.clientid
    url      = local.bot-secret.url
  })
  filename = "bot-secret.json"
}
