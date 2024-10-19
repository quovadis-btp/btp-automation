// https://github.com/hashicorp/terraform-provider-tfe/issues/187#issuecomment-739129017
// https://stackoverflow.com/questions/66598788/terraform-how-can-i-reference-terraform-cloud-environmental-variables
// https://www.env0.com/blog/terraform-functions-guide-complete-list-with-examples
// https://developer.hashicorp.com/terraform/cloud-docs/run/run-environment#environment-variables

// https://spacelift.io/blog/terraform-workspaces
// Terraform Workspaces helps us to manage multiple deployments of the same configuration. 
//
// https://developer.hashicorp.com/terraform/cloud-docs/run/run-environment#environment-variables
//
variable "TFC_WORKSPACE_NAME" {
  // HCP Terraform automatically injects the following environment variables for each run. 
  description = "The name of the workspace used in this run."
  type        = string
}

variable "TFC_PROJECT_NAME" {
  // HCP Terraform automatically injects the following environment variables for each run. 
  description = "The name of the project used in this run."
  type        = string
}

variable "TFC_WORKSPACE_SLUG" {
  // HCP Terraform automatically injects the following environment variables for each run. 
  description = "The slug consists of the organization name and workspace name, joined with a slash."
  type        = string
}

variable "TFC_CONFIGURATION_VERSION_GIT_BRANCH" {
  // HCP Terraform automatically injects the following environment variables for each run. 
  description = "The name of the branch that the associated Terraform configuration version was ingressed from."
  type        = string
  default     = "main"
}

variable "TFC_CONFIGURATION_VERSION_GIT_COMMIT_SHA" {
  // HCP Terraform automatically injects the following environment variables for each run. 
  description = "The full commit hash of the commit that the associated Terraform configuration version was ingressed from."
  type        = string
}

variable "TFC_CONFIGURATION_VERSION_GIT_TAG" {
  // HCP Terraform automatically injects the following environment variables for each run. 
  description = "The name of the tag that the associated Terraform configuration version was ingressed from."
  type        = string
}

// organization:<MY-ORG-NAME>:project:<MY-PROJECT-NAME>:workspace:<MY-WORKSPACE-NAME>:run_phase:<plan|apply>.
locals {
  organization_name = split("/", var.TFC_WORKSPACE_SLUG)[0]
  user_plan = "organization:${local.organization_name}:project:${var.TFC_PROJECT_NAME}:workspace:${var.TFC_WORKSPACE_NAME}:run_phase:plan"
  user_apply = "organization:${local.organization_name}:project:${var.TFC_PROJECT_NAME}:workspace:${var.TFC_WORKSPACE_NAME}:run_phase:apply"
}

output "user_plan" {
  value = local.user_plan
}

output "user_apply" {
  value = local.user_apply
}