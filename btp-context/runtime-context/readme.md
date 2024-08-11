Here are the references for the IAS Trust Setup:
Terraform Resource: https://registry.terraform.io/providers/SAP/btp/latest/docs/resources/subaccount_trust_configuration  


Sample with Trust Setup to a Custom IAS: https://github.com/SAP-samples/btp-terraform-samples/blob/main/released/discovery_center/mission_3061/step1/main.tf#L101-L104  

Here is also one sample that shows how to conditionally create the Trust Setup: 
https://github.com/SAP-samples/btp-terraform-samples/blob/22d58c3f542530c0a034fbb560e235a836e63284/released/discovery_center/mission_4259/main.tf#L29-L34  
-> count Keyword with ternary operator that allows to create the trust depending on a variable
 