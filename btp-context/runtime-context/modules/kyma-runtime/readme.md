bootstrap a kyma cluster
==============

### configure runtime context using a terrafrom module

```
module "runtime_context" {
  source             = "../../kyma-runtime"

  BTP_GLOBAL_ACCOUNT = var.BTP_GLOBAL_ACCOUNT
  BTP_BOT_USER       = var.BTP_BOT_USER
  BTP_SA_REGION      = var.BTP_SA_REGION
  BTP_SUBACCOUNT     = var.BTP_SUBACCOUNT
  BTP_BOT_PASSWORD   = var.BTP_BOT_PASSWORD
  BTP_CUSTOM_IDP     = var.BTP_CUSTOM_IDP
  BTP_BACKEND_URL    = var.BTP_BACKEND_URL
  BTP_KYMA_PLAN      = var.BTP_KYMA_PLAN
   
  emergency_admins   = var.emergency_admins
  launchpad_admins   = var.launchpad_admins
  cluster_admins     = var.cluster_admins

  BTP_KYMA_DRY_RUN   = var.BTP_KYMA_DRY_RUN

  service_plan__build_workzone = var.service_plan__build_workzone

  argocd_username    = var.argocd_username
  argocd_password    = var.argocd_password
  argocd_tokenurl    = var.argocd_tokenurl
  argocd_clientid    = var.argocd_clientid

  argocd_url         = var.argocd_url
}
```


<table style="width: 100%; border-collapse: collapse; background-color: #f5f5f5;" border="1">
<tbody>
<tr style="height: 193px;">
<td style="width: 71.6%; height: 193px;">
<div>
<h1><a href=""><img class="aligncenter" src="https://github.com/user-attachments/assets/742bc0db-512a-4b81-83c2-7dc9b1833f66" alt="" /></a></h1>
</div>
</td>
</tr>
</tbody>
</table>



## Troubleshooting kyma cluster

### Working with kyma modules

More often then seldom, after the kymaruntime environment has been created, its kyma cluster is still not necessarily ready.  
This stems from the fact that kyma modules are being deployed asynchronously and no-blocking the kymaruntime environment rendering.  
For instance, the api-gateway module mat still not be ready severla minutes after the kymaruntime environment creation.  

<table style="width: 100%; border-collapse: collapse; background-color: #f5f5f5;" border="1">
<tbody>
<tr style="height: 193px;">
<td style="width: 71.6%; height: 193px;">
<div>
<h1><a href="https://gist.github.com/ptesny/2a6fce8d06a027f9e3b86967aeddf984#file-working-with-kyma-modules-md"><img class="aligncenter" src="https://github.com/user-attachments/assets/348e69bf-faf6-413d-9a6d-7c463e738170" alt="" /></a></h1>
</div>
</td>
</tr>
</tbody>
</table>



## Troubleshooting terraform

### Communication breakdown with the BTP CLI server

This may happen due to the loss of the internet connectivity 

```
╷
│ Error: API Error Creating Resource Environment Instance (Subaccount)
│ 
│   with module.runtime_context.btp_subaccount_environment_instance.kyma[0],
│   on ../../kyma-runtime/bootstrap-kymaruntime.tf line 20, in resource "btp_subaccount_environment_instance" "kyma":
│   20: resource "btp_subaccount_environment_instance" "kyma" {
│ 
│ Post "https://cli.btp.cloud.sap/command/v2.64.0/accounts/environment-instance?get": read tcp 10.xx.xx.xx:49302->3.xx.xx.xx:443: read: connection
│ reset by peer
╵
```
In the afermath of this we may need re-synchronize the terraform state with the actual infrastructure configuration.  

One can check the terraform state if there is already an entry via terraform state list.  
And if yes, first remove the entry from the state via terraform state rm: Command: state rm | Terraform | HashiCorp Developer
 
Then, import the Kyma resource via an import block

### Removing Resources 

  * [Removing Resources](https://developer.hashicorp.com/terraform/language/resources/syntax#removing-resources)  

```
terraform state rm -dry-run btp_subaccount_environment_instance.kyma

Would have removed nothing.

```

```
terraform state rm module.runtime_context.btp_subaccount_environment_instance.kyma


Removed module.runtime_context.btp_subaccount_environment_instance.kyma[0]
```

  * add the import.tf with the resources to import
```
import {
  to = module.runtime_context.btp_subaccount_environment_instance.kyma[0]
  id = "<subaccount id>,<environment id>"
}
```
  * run the terraform apply

### Error acquiring the state lock  

If one has abruptly closed/aborted a terraform plan/apply command and now it's throwing the below error message when using terraform commands in the terminal, namely **Error acquiring the state lock**.  


```
terraform apply -var-file="89982f73trial/btp-trial.tfvars"
╷
│ Error: Error acquiring the state lock
│ 
│ Error message: the state is already locked by another terraform client
│ Lock Info:
│   ID:        e82af8c1-8bb0-0507-6b1a-c7909a9cbcb2
│   Path:      
│   Info:      
│ 
│ Terraform acquires a state lock to protect the state from being written
│ by multiple users at the same time. Please resolve the issue above and try
│ again. For most commands, you can disable locking with the "-lock=false"
│ flag, but this is not recommended.
╵
```

Disabling the lock state is not recommended but may be the first ad-hoc remedy

```
terraform apply -var-file="btp-trial.tfvars" -lock=false
```

#### How does one break the lease of a state file ?

One can forcefully unlock the state: https://developer.hashicorp.com/terraform/cli/commands/force-unlock

```
terraform force-unlock e82af8c1-8bb0-0507-6b1a-c7909a9cbcb2
Do you really want to force-unlock?
  Terraform will remove the lock on the remote state.
  This will allow local Terraform commands to modify this state, even though it
  may still be in use. Only 'yes' will be accepted to confirm.

  Enter a value: yes

Terraform state has been successfully unlocked!

The state has been unlocked, and Terraform commands should now be able to
obtain a new lock on the remote state.

```

## Miscallenous

Here are the references for the IAS Trust Setup:  
Terraform Resource: 
  * https://registry.terraform.io/providers/SAP/btp/latest/docs/resources/subaccount_trust_configuration  


Sample with Trust Setup to a Custom IAS:  
  * https://github.com/SAP-samples/btp-terraform-samples/blob/main/released/discovery_center/mission_3061/step1/main.tf#L101-L104  

Here is also one sample that shows how to conditionally create the Trust Setup:  
  * https://github.com/SAP-samples/btp-terraform-samples/blob/22d58c3f542530c0a034fbb560e235a836e63284/released/discovery_center/mission_4259/main.tf#L29-L34  

