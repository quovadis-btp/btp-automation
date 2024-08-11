resource "btp_subaccount" "this" {
  name      = var.subaccount_name
  subdomain = var.subdomain
  region    = var.BTP_REGION
}

module "sap_kyma_runtime" {
  source         = "../../sap-kyma-runtime" 
  name           = var.KYMARUNTIME_NAME
  administrators = var.administrators
  subaccount_id  = btp_subaccount.this.id
  plan           = var.KYMARUNTIME_PLAN
  kyma_config_template = jsondecode(jsonencode({
      "name": "",
      "region": "",
      "machineType": "",
      "autoScalerMin": 3,
      "autoScalerMax": 5,
      "modules": {
          "list": [
              {
                  "name": "api-gateway",
                  "channel": "regular"
              },
              {
                  "name": "istio",
                  "channel": "regular"
              },
              {
                  "name": "btp-operator",
                  "channel": "regular"
              },
              {
                  "name": "serverless",
                  "channel": "regular"
              },
              {
                  "name": "connectivity-proxy",
                  "channel": "regular"
              }
          ]
      },    
      "administrators": [
 
      ],
      "oidc": {
          "clientID": "1c7978d7-91f7-415b-8bbb-5323f10d5349",
          "groupsClaim": "groups",
          "issuerURL": "https://aqx46aatc.trial-accounts.ondemand.com",
          "signingAlgs": [
              "RS256"
          ],
          "usernameClaim": "sub",
          "usernamePrefix": "-"
      }
  })
  )
}
