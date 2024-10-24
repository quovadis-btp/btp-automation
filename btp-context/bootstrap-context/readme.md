bootstrap context
==============

What does bootstrapping mean ? It's like one needs an oven to bake a pizza. No oven, no pizza.


<table style="width: 100%; border-collapse: collapse; background-color: #f5f5f5;" border="1">
<tbody>
<tr style="height: 193px;">
<td style="width: 71.6%; height: 193px;">
<div>
<h1><a href=""><img class="aligncenter" src="https://github.com/user-attachments/assets/73d4722d-bd26-4d08-a318-8b0e1b2ff435" alt="" /></a></h1>
</div>
</td>
</tr>
</tbody>
</table>


### bootstrap a global account

Likewise, one needs to get a btp global account in order to have all the services entitled and ready for use.  

In a nutshell, a BTP global account has an owner (administrator) and comes with a set of entitled services based on a commercial agreement.  

For instance, whenever one creates a BTP trial account, one becomes the legal owner and a designated administrator of it.  
As this is a trial agreement, (limited to a maximum period of 90 days), a predefined set of services with their entitlements is already baked into the agreement. 

<table style="width: 100%; border-collapse: collapse; background-color: #f5f5f5;" border="1">
<tbody>
<tr style="height: 193px;">
<td style="width: 71.6%; height: 193px;">
<div>
<h1><a href=""><img class="aligncenter" src="https://github.com/user-attachments/assets/03f0bf15-45e9-47c1-b5d1-d587696e0612" alt="" /></a></h1>
</div>
<div>
<h1><a href=""><img class="aligncenter" src="https://github.com/user-attachments/assets/f2471511-c09c-4215-8aaf-0bb3e47c2944" alt="" /></a></h1>
</div>
</td>
</tr>
</tbody>
</table>


### prepare a global account for contextual automation.  

All that is required to bootstrap the global account context is to provide following information:
  * btp-trial.tfvars

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

# optionally, you may pick an existing SAP Cloud Identity Services tenant as your custom idp
idp                       = ""

```
The user who created a global account has already an S-user identifier and is known to the SAP Identity Provider (SAP ID).  

**The bootstrap script must be run by this global account owner/administrator.**    

This will result in a bootstrap context subaccount having been created as a placeholder for the custom identity provider, as depicted below:  

<table style="width: 100%; border-collapse: collapse; background-color: #f5f5f5;" border="1">
<tbody>
<tr style="height: 193px;">
<td style="width: 71.6%; height: 193px;">
<div>
<h1><a href=""><img class="aligncenter" src="https://github.com/user-attachments/assets/f0bafaa5-134e-4495-9d8e-4836e9fbf2c7" alt="" /></a></h1>
</div>
<div>
<h1><a href=""><img class="aligncenter" src="https://github.com/user-attachments/assets/0b1f0199-f515-4311-a080-de72af59d759" alt="" /></a></h1>
</div>
</td>
</tr>
</tbody>
</table>


The terraform script will create/re-use a custom SAP Cloud Identity services tenant to be used both as a platform and application custom idp.  

This custom SAP Cloud Identity services tenant is different from SAP ID/Universal ID.  
In case of creation, the tf script runner user will be sent an onboarding email to this custom idp.  
It is important the tf runner user gets onboarded to the custom idp as its administrator.  

The platform admins will be the addtiional administrators allowed to manage the global account assets.   
As the tf script runner becomes the custom idp administrator, she or he may choose these additional users however she or he likes.  

My recommendation is one of these additional platform users is a technical user whose email address is not registered with the SAP ID/Universal ID.  

```
terraform init -upgrade                             

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

```
terraform plan -var-file="btp-trial.tfvars" -refresh-only
Acquiring state lock. This may take a few moments...
var.password
  The password of the SAP BTP Global Account Administrator

  Enter a value: <password of one of the ga administrators>

module.custom_idp.data.external.free-trial-postgresql-quota: Reading...
module.custom_idp.data.external.free-trial-kymaruntime-quota: Reading...
module.custom_idp.data.btp_subaccounts.all: Reading...
module.custom_idp.data.btp_subaccount.context: Reading...
module.custom_idp.data.btp_subaccounts.all: Read complete after 0s [id=2392906ftrial-ga]
module.custom_idp.data.btp_subaccount_environment_instances.trial: Reading...
module.custom_idp.data.btp_subaccount.context: Read complete after 0s [id=4bb888d1-57c1-4c48-884c-04c079889b06]
module.custom_idp.data.btp_subaccount_environment_instances.trial: Read complete after 1s [id=32d6af28-d355-43ef-a4ff-aeaeb62bfe3e]
module.custom_idp.data.external.free-trial-kymaruntime-quota: Read complete after 4s [id=-]
module.custom_idp.data.external.free-trial-postgresql-quota: Read complete after 4s [id=-]

No changes. Your infrastructure still matches the configuration.

Terraform has checked that the real remote objects still match the result of your most recent changes, and found no differences.
Releasing state lock. This may take a few moments...
```

