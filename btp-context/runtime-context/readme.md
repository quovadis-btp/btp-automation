BTP landscapes automation. Applying context semantics.
====================

<img width="1109" alt="image" src="https://github.com/user-attachments/assets/bff29409-2b47-466f-9773-59c7ec977127">

<img width="1254" alt="image" src="https://github.com/user-attachments/assets/742bc0db-512a-4b81-83c2-7dc9b1833f66">



### bootstrap a global account

Bootstrap a global account to make it ready for contextual automation

```
terraform init -upgrade                             
Initializing the backend...
Upgrading modules...
- custom_idp in ../../custom-idp
Initializing provider plugins...
- Finding sap/btp versions matching ">= 1.5.0, ~> 1.5.0"...
- Finding latest version of hashicorp/random...
- Finding latest version of hashicorp/local...
- Finding latest version of hashicorp/external...
- Using previously-installed sap/btp v1.5.0
- Using previously-installed hashicorp/random v3.6.2
- Using previously-installed hashicorp/local v2.5.1
- Using previously-installed hashicorp/external v2.3.3
```


```
terraform plan -var-file="btp-trial.tfvars"
var.password
  The password of the SAP BTP Global Account Administrator

  Enter a value: <password of one of the ga administrators>
```

### configure runtime context

```
terraform init -upgrade
                  
Initializing the backend...
Initializing provider plugins...
- terraform.io/builtin/terraform is built in to Terraform
- Finding sap/btp versions matching "1.5.0"...
- Finding massdriver-cloud/jq versions matching "0.2.0"...
- Finding latest version of hashicorp/random...
- Finding latest version of hashicorp/local...
- Finding latest version of hashicorp/null...
- Finding latest version of hashicorp/http...
- Finding latest version of salrashid123/http-full...
- Using previously-installed hashicorp/random v3.6.2
- Using previously-installed hashicorp/local v2.5.1
- Using previously-installed hashicorp/null v3.2.2
- Using previously-installed hashicorp/http v3.4.4
- Using previously-installed salrashid123/http-full v1.3.1
- Using previously-installed sap/btp v1.5.0
- Using previously-installed massdriver-cloud/jq v0.2.0

Terraform has been successfully initialized!


``` 

### configure provider context


### miscallenous

Here are the references for the IAS Trust Setup:  
Terraform Resource: 
  * https://registry.terraform.io/providers/SAP/btp/latest/docs/resources/subaccount_trust_configuration  


Sample with Trust Setup to a Custom IAS:  
  * https://github.com/SAP-samples/btp-terraform-samples/blob/main/released/discovery_center/mission_3061/step1/main.tf#L101-L104  

Here is also one sample that shows how to conditionally create the Trust Setup:  
  * https://github.com/SAP-samples/btp-terraform-samples/blob/22d58c3f542530c0a034fbb560e235a836e63284/released/discovery_center/mission_4259/main.tf#L29-L34  

