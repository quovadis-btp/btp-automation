btp contexts
=============

BTP contexts are a way of defining logical entities to host amd implement various contexts, namely bootstrap, runtime, provider and consumer.  

The main idea behind the contexts is to break silos of global account, subaccounts across different regions and break free from 
the rigidity of the cloud foundry runtime org structure.

In a nutshell, contexts are declarative entities, defined as terraform scripts and orchestrated by CI/CD pipelines. 


terraform
========

### Terraform Visual CLI  

  * https://www.npmjs.com/package/@terraform-visual/cli#terraform-visual-cli  
  * https://github.com/hieven/terraform-visual?tab=readme-ov-file
  * https://developer.hashicorp.com/terraform/tutorials/state/refresh

```
terraform plan -var-file="89982f73trial/btp-trial.tfvars" -out=plan.out
terraform show -json plan.out > plan.json
terraform-visual --plan plan.json
open terraform-visual-report/index.html
```
![image](https://github.com/user-attachments/assets/5792cec6-0941-4076-8af9-81021c4c1abf)


### terraform graph

```
terraform graph --help
terraform graph -type=plan | dot -Tpng -o graph.png
```

### Keeping the terraform state in a Kubernetes Secret  

  * https://pet2cattle.com/2022/04/terraform-remote-state-kubernetes
```
kubectl get secret tfstate-default-state-89982f73trial  -n tf-runtime-context --kubeconfig ~/.kube/kubeconfig--c-4860efd-default.yaml -o jsonpath="{.data.tfstate}" | base64 -d | gzip -d > toto.json
```




### Useful links  
  * https://spacelift.io/blog/terraform-best-practices
  * https://github.com/spacelift-io-blog-posts/Blog-Technical-Content/tree/master/terraform-best-practices
  * https://github.com/spacelift-io-blog-posts/Blog-Technical-Content
  * https://github.com/SAP-samples/btp-terraform-samples
  * https://registry.terraform.io/providers/SAP/btp/latest/docs
  * https://registry.terraform.io/providers/oboukili/argocd/latest/docs/data-sources/application
  * https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
  * https://developers.sap.com/tutorials/btp-terraform-get-started.html
  * https://github.com/aydin-ozcan/terraform-btp-sap-btp-entitlements/tree/main

  * https://spacelift.io/blog/terraform-ignore-changes
  * https://spacelift.io/blog/terraform-yaml#what-is-the-yamldecode-function-in-terraform
  * https://spacelift.io/blog/terraform-jsonencode#example-6-creating-iam-policies-using-jsonencode-function
  * https://developer.hashicorp.com/terraform/language/meta-arguments/for_each
  * https://spacelift.io/blog/terraform-count
  * https://stackoverflow.com/questions/75840856/how-to-trigger-resource-replacement-in-terraform-if-resource-atrtibute-changed
  * https://xebia.com/blog/replace-terraform-resources-based-on-other-changes-with-replace-triggered-by/
  * https://developer.hashicorp.com/terraform/language/resources/terraform-data
  * https://developer.hashicorp.com/terraform/language/resources/terraform-data#output
  * https://developer.hashicorp.com/terraform/language/resources/terraform-data#example-usage-null_resource-replacement
  * https://developer.hashicorp.com/terraform/language/functions/nonsensitive
  * https://balaskas.gr/blog/2022/11/11/gitlab-as-a-terraform-state-backend/
  * https://medium.com/@vinoji2005/using-terraform-with-kubernetes-a-comprehensive-guide-237f6bbb0586
  * https://developer.hashicorp.com/terraform/language/settings/backends/kubernetes
  * https://spacelift.io/blog/terraform-alternatives#1-opentofu
  * https://developer.hashicorp.com/terraform/language/state/remote-state-data#the-terraform_remote_state-data-source
  * https://ourcloudschool.medium.com/read-terraform-provisioned-resources-with-terraform-remote-state-datasource-ab9cf882ab63
  * https://spacelift.io/blog/terraform-remote-state
  * https://developer.hashicorp.com/terraform/tutorials/state/troubleshooting-workflow#correct-a-for_each-error
  * https://kodekloud.com/blog/terraform-for_each/#:~:text=for_each%20is%20commonly%20used%20to,%2C%20data%2C%20or%20module%20blocks.
  * https://developer.hashicorp.com/terraform/tutorials/configuration-language/for-each
  * https://developer.hashicorp.com/terraform/language/meta-arguments/for_each
  * https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax

  * https://github.com/eugenp/tutorials/blob/master/linux-bash-modules/linux-bash-json/src/main/bash/jq.sh
  * https://ec.haxx.se/how-to-read.html
  * https://jqlang.github.io/jq/manual/
  * https://kubernetes.io/blog/2023/08/21/kubernetes-1-28-jobapi-update/#pod-replacement-policy

  * https://help.sap.com/docs/btp/sap-business-technology-platform/provisioning-and-update-parameters-in-kyma-environment#loioe2e13bfaa2f54a4fb179f0f1f840353a__section_Machine_Type
