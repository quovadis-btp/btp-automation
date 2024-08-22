bootstrap context
==============

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


<img width="1123" alt="image" src="https://github.com/user-attachments/assets/678b73a3-a1d0-4b71-a436-ed3eab50dea8">


<img width="1269" alt="image" src="https://github.com/user-attachments/assets/568b7cbc-edc7-4947-a0fc-1fa972943cfa">

