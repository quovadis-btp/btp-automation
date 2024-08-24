bootstrap context
==============

What does bootstrapping mean ? It's like one needs an oven to bake a pizza. No oven, no pizza.


<table style="width: 100%; border-collapse: collapse; background-color: #f5f5f5;" border="1">
<tbody>
<tr style="height: 193px;">
<td style="width: 71.6%; height: 193px;">
<div>
<h1><a href=""><img class="aligncenter" src="https://github.com/user-attachments/assets/3cb11e9e-a9af-4b9e-8e84-908ad0afa301" alt="" /></a></h1>
</div>
</td>
</tr>
</tbody>
</table>


### bootstrap a global account

Likewise, one needs to get a btp global account in order to have all the services entitled and ready for use.  
In a nutshell, a BTP global account has an owner (administrator) with a set of entitled services based on the commercial agreement.  

For instance, when one creates a BTP trial account one becomes the legal owner and administrator of it.  
As this is a trial agreement, [limited to a maximum period of 90 days], a predefined set of services with their entitllements is already baked in. 


<table style="width: 100%; border-collapse: collapse; background-color: #f5f5f5;" border="1">
<tbody>
<tr style="height: 193px;">
<td style="width: 71.6%; height: 193px;">
<div>
<h1><a href=""><img class="aligncenter" src="https://github.com/user-attachments/assets/678b73a3-a1d0-4b71-a436-ed3eab50dea8" alt="" /></a></h1>
</div>
<div>
<h1><a href=""><img class="aligncenter" src="https://github.com/user-attachments/assets/568b7cbc-edc7-4947-a0fc-1fa972943cfa" alt="" /></a></h1>
</div>

</td>
</tr>
</tbody>
</table>

### prepare a global account for contextual automation.  

All that is required the following information:

```
globalaccount             = "<global account subdomain name>"
username                  = "<email address of the ga administrator>"
region                    = "btp region: ap21 or us10"
subaccount_name           = "btp-bootstrap"
subdomain                 = "btp-bootstrap"

#
# the global account owner must be excluded from the emergency admin list
#
emergency_admins          = ["admin1@acme.com", "admin2@acme.com"]
platform_admins           = ["platform-admin1@acme.com", "platform-admin2@acme.com"]

```

A user who created a global account has already an S-user identifier and is known to the SAP Identity Provider (SAP ID).  
The booster script must be run by any SAP ID global account owner/administrator.  

The terraform script will create a custom SAP Cloud Identity services tenant to be used both as a platform and application custom idp.  
This custom SAP Cloud Identity services tenant is different from SAP ID/Universal ID.  
The the tf script runner will receive an onboarding email to this custom idp.

The platform admins will be addtiional users allowed to manage the global account assets.  
The tf script runner becomes the custom idp administrators and thus may choose these users additional however he likes.  
My recommendation is one of these additional platform users is a technical user.  

```
terraform init -upgrade                             
terraform init -reconfigure
    
Successfully configured the backend "kubernetes"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing modules...
Initializing provider plugins...
- terraform.io/builtin/terraform is built in to Terraform
- Reusing previous version of hashicorp/random from the dependency lock file
- Reusing previous version of hashicorp/local from the dependency lock file
- Reusing previous version of hashicorp/external from the dependency lock file
- Reusing previous version of sap/btp from the dependency lock file
- Using previously-installed hashicorp/random v3.6.2
- Using previously-installed hashicorp/local v2.5.1
- Using previously-installed hashicorp/external v2.3.3
- Using previously-installed sap/btp v1.5.0

Terraform has been successfully initialized!
```


```
terraform plan -var-file="btp-trial.tfvars"
var.password
  The password of the SAP BTP Global Account Administrator

  Enter a value: <password of one of the ga administrators>
```

<table style="width: 100%; border-collapse: collapse; background-color: #f5f5f5;" border="1">
<tbody>
<tr style="height: 193px;">
<td style="width: 71.6%; height: 193px;">
<div>
<h1><a href=""><img class="aligncenter" src="https://github.com/user-attachments/assets/326f2e3c-d7bf-4fcf-b177-6834d63d8577" alt="" /></a></h1>
</div>
</td>
</tr>
</tbody>
</table>

