# Terraform Module for SAP HANA Cloud on SAP BTP

This Terraform module provisions and manages SAP HANA Cloud resources on the SAP Business Technology Platform (BTP). It simplifies the process of setting up SAP HANA Cloud databases, assigning role collections, and managing entitlements within a subaccount.

## Requirements

- Terraform v1.0 or higher
- SAP BTP Provider for Terraform v1.3.0 or higher
- An SAP BTP account with sufficient permissions to manage resources

### Usage

To use this module in your Terraform environment, you can clone it from the GitHub repository and reference it in your Terraform configuration like so:

```hcl
module "sap_hana_cloud" {
  source = "github.com/ptesny/terraform-sap-hana-cloud"

  subaccount_id             = "<subaccount-id>"
  service_name              = "hana"
  plan_name                 = "hana-plan"
  hana_cloud_tools_app_name = "hana-tools-app"
  hana_cloud_tools_plan_name= "hana-tools-plan"
  admins                    = ["admin@example.com"]
  viewers                   = ["viewer@example.com"]
  security_admins           = ["sec-admin@example.com"]
  instance_name             = "my-hana-instance"
  memory                    = 16
  vcpu                      = 1
  whitelist_ips             = ["0.0.0.0"]
  database_mappings         = [
    # provide mappings for cf or kyma env
    {
      organization_guid = # your cf org id
      space_guid        = # your space guid
    }
  ]
}
```

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `subaccount_id` | The ID of the SAP BTP subaccount. | `string` | n/a | yes |
| `instance_name` | Name of the SAP HANA Cloud instance. | `string` | `hana-cloud` | no |
| `hana_cloud_tools_app_name` | Application name for HANA Cloud tools. | `string` | `hana-cloud-tools` | no |
| `hana_cloud_tools_plan_name` | Plan name for HANA Cloud tools. | `string` | `tools` | no |
| `service_name` | The name of the service to be entitled and used. | `string` | `hana-cloud` | no |
| `plan_name` | The name of the service plan for SAP HANA Cloud. | `string` | `hana-td` | no |
| `admins` | List of admin user emails. | `list(string)` | `[]` | no |
| `viewers` | List of viewer user emails. | `list(string)` | `[]` | no |
| `security_admins` | List of security admin user emails. | `list(string)` | `[]` | no |
| `memory` | Amount of memory allocated to the HANA instance in GB. | `number` | `32` | no |
| `vcpu` | Number of virtual CPUs allocated to the instance. | `number` | `2` | no |
| `whitelist_ips` | List of IP addresses whitelisted for access. | `list(string)` | `[]` | no |
| `database_mappings` | Database mappings configuration. | `list(any)` | `null` | no |

### Outputs

This module does not output any values.

### Contributing

Contributions to this module are welcome. Please ensure that your pull requests are well-documented and include test cases where applicable.

### License

Apache 2 Licensed. See [LICENSE](https://github.com/codeyogi911/terraform-sap-hana-cloud/blob/main/LICENSE) for full details.
