# Terraform provider_context module

This Terraform module helps provision and manage provider context resources on the SAP Business Technology Platform (BTP). 
It simplifies the process of setting up SAP HANA Cloud databases, destinations and all other BTP resources that may be required to implement a SaaS provider application 

### Module usage

```hcl
module "provider_context" {
  source                     = "../../sap-hana-cloud"

  globalaccount              = var.globalaccount
  username                   = var.username
  subdomain                  = var.subdomain
  subaccount_name            = var.subaccount_name 
  region                     = var.region
  password                   = var.password
  idp                        = var.idp

  service_name               = var.service_name
  plan_name                  = var.plan_name
  hana_cloud_tools_app_name  = var.hana_cloud_tools_app_name
  hana_cloud_tools_plan_name = var.hana_cloud_tools_plan_name

  memory                     = var.memory
  vcpu                       = var.vcpu
  storage                    = var.storage

  instance_name              = var.instance_name
  admins                     = var.admins
  emergency_admins           = var.emergency_admins
  launchpad_admins           = var.launchpad_admins
  service_plan__build_workzone = var.service_plan__build_workzone

  subaccount_id              = var.subaccount_id
  whitelist_ips              = ["0.0.0.0/0"]
```

### Inputs

### Outputs

<img width="1292" alt="image" src="https://github.com/user-attachments/assets/4f0c8cdd-a22e-4b95-8b70-a3569e7175c5">
