bootstrap context
==============


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


### bootstrap a global account

What does bootstrapping mean ? It's like you need an oven to bake a pizza. No oven, no pizza.


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


### Bootstrap a global account to make it ready for contextual automation.  

Likewise, one needs to get a btp global account in order to have all the services entitled and ready for use.  
In a nutshell, a BTP global account has an owner (administrator) with a set of entitled services based on the commercial agreement.  

For instance, when one creates a BTP trial account one becomes the legal owner and administrator of it.  
As this is a trial agreement, [limited to a maximum period of 90 days], a predefined set of services with their entitllements is already baked in. 

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

