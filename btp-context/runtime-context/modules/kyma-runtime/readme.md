bootstrap a kyma cluster
==============

### configure runtime context with a terrafrom modul;e

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


<img width="1254" alt="image" src="https://github.com/user-attachments/assets/742bc0db-512a-4b81-83c2-7dc9b1833f66">




PS.
Both cf and k8s runtimes can be used jointly or seperately in their respective runtime contexts



[cf architecture](https://docs.cloudfoundry.org/concepts/architecture/)  
![image](https://github.com/user-attachments/assets/83226447-29d4-4ae4-89d7-47354154dd9f)


[k8s architecture](https://phoenixnap.com/kb/understanding-kubernetes-architecture-diagrams)  
![image](https://github.com/user-attachments/assets/649532ff-d679-4ea9-884d-c3fbd6edc528)


### configure provider context


### miscallenous

Here are the references for the IAS Trust Setup:  
Terraform Resource: 
  * https://registry.terraform.io/providers/SAP/btp/latest/docs/resources/subaccount_trust_configuration  


Sample with Trust Setup to a Custom IAS:  
  * https://github.com/SAP-samples/btp-terraform-samples/blob/main/released/discovery_center/mission_3061/step1/main.tf#L101-L104  

Here is also one sample that shows how to conditionally create the Trust Setup:  
  * https://github.com/SAP-samples/btp-terraform-samples/blob/22d58c3f542530c0a034fbb560e235a836e63284/released/discovery_center/mission_4259/main.tf#L29-L34  

