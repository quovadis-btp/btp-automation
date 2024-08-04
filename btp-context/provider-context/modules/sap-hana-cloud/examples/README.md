# Example Configuration for SAP HANA Cloud Terraform Module

This example illustrates how to use the SAP HANA Cloud Terraform module to create a SAP BTP subaccount and deploy an SAP HANA Cloud instance with basic configurations.

## Prerequisites

Before you begin, ensure you have the following:

- Terraform v1.0 or higher installed
- Access to an SAP BTP Global Account with the necessary permissions

### Usage

To run this example, you need to perform the following steps:

1. **Clone the repository**:

   ```bash
   git clone https://github.com/ptesny/terraform-sap-hana-cloud.git
   cd terraform-sap-hana-cloud/examples
   ```

2. **Initialize Terraform**:
   Run `terraform init` to initialize a working directory with Terraform configuration files.

3. **Create a `terraform.tfvars` file**:
   Create a `terraform.tfvars` file or set the required variables in your environment to provide values for the required variables.

4. **Plan and Apply**:
   Execute the following commands to plan and apply the Terraform configuration:

   ```bash
   terraform plan
   terraform apply
   ```

### Variables

The following variables need to be configured to use this example:

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| `subaccount_name` | The name of the SAP BTP Subaccount. | `string` | yes |
| `subdomain` | The subdomain of the SAP BTP Subaccount. | `string` | yes |
| `admins` | List of email addresses for the SAP BTP Subaccount Administrators. | `list(string)` | yes |
| `globalaccount` | The name of the SAP BTP Global Account. | `string` | yes |
| `username` | The username of the SAP BTP Global Account Administrator. | `string` | yes |
| `password` | The password of the SAP BTP Global Account Administrator. | `string` | yes |

### Configuration

This example sets up a subaccount within a specific region and uses the main module to deploy an SAP HANA Cloud instance with the specified administrators and open network access. Adjust the IP whitelisting and other parameters according to your security requirements.

### Outputs

Currently, this example does not produce any outputs. Modify the configuration to include outputs as needed for your infrastructure.
