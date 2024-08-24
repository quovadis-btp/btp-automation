btp contexts
=============

BTP contexts are logical entities defined to host and implement various infrastructure contexts, namely bootstrap, runtime, provider and consumer.  

The main idea behind the contexts is the ability to combine and maintain resources from global accounts with their subaccounts across different regions and break free from 
the rigidity of the cloud foundry runtime org structure.

In a nutshell, the contexts are declarative entities, defined as terraform scripts, eventually, orchestrated by CI/CD pipelines.  


<table style="width: 100%; border-collapse: collapse; background-color: #f5f5f5;" border="1">
<tbody>
<tr style="height: 193px;">
<td style="width: 71.6%; height: 193px;">
<div>
<h1><a href=""><img class="aligncenter" src="https://github.com/user-attachments/assets/07e1758d-610e-4e16-b90a-ad9524ed9b4d" alt="" /></a></h1>
</div>
</td>
</tr>
</tbody>
</table>

Business Landscape Automation
==========


<table style="width: 100%; border-collapse: collapse; background-color: #ebf8ff;" border="1">
<tbody>
<tr>
<td style="width: 100%;"><details open="open"><summary>Table of Contents</summary>

<ol>
 	<li><a href="#btp-automation">Bootstrap toolkit for business users.</a></li>
 	<li><a href="#terraform-automation">terraform.</a></li>
</ol>

</details></td>
</tr>
</tbody>
</table>

<h2 id="btp-automation">1. Bootstrap toolkit for business users.</h2>

Likewise, driving a car, seldom requires opening the bonnet, business users focus on functionality.  

The btp contexts abstraction lays ground for a generic receipe that makes the provisioning and houskeeping of a BTP landscape with kyma runtime environment and BTP backing services a rather pleasant experience for the business users.  

To make this receipe a reality, I have coined a term of a _depleted_ runtime environment that comprises one or several kyma clusters accompanied with a restricted set of BTP services (for instance, a _depleted_ environment may not need to have the XSUAA service entitlement.)

However, all the kernel and business BTP services are available in a dedicated provider context (a provider subaccount) and are mereley referenced from kyma clusters (via a service sharing mechanism).  

This makes it possible for each kyma cluster to be torn down, detached, (re-)attached to a provider context.  

Additionally, a provider can be located in a different BTP landscape (with a different global account and/or in different BTP region (data center) as well).  

Or, even one could have the provider implemented with either a hybrid or a foreign, non-BTP landscape.  
For instance, a provider context could be implemented with other hyperscaler's services or with a mix of BTP and multicloud hyperscalers services.

Furthermore, this approach allows for _location and data center transparency_ with the _intrinsic failover_ between runtime and provider(s) contexts.  

<h2 id="terraform-automation">2. terraform.</h2>  

Terraform allows to plan, apply and maintain the desired state of the contextual infrastructure.  
This is made possible by a [rich ecosystem of providers](https://registry.terraform.io/browse/providers).  
Providers are a logical abstraction of an upstream API. They are responsible for understanding API interactions and exposing resources.  

For instance, the dedicated SAP BTP [terraform provider](https://registry.terraform.io/providers/SAP/btp/latest/docs) is leveraging the BTP CLI API (on the server side).  
Additionally, each provider has its own ecosystem of modules, self-contained packages of Terraform configurations that are managed as a group.  
For instance, for sap btp: https://registry.terraform.io/providers/SAP/btp/latest

<table style="width: 100%; border-collapse: collapse; background-color: #f5f5f5;" border="1">
<tbody>
<tr style="height: 193px;">
<td style="width: 71.6%; height: 193px;">
<div>
<h1><a href="https://registry.terraform.io/providers/SAP/btp/latest"><img class="aligncenter" src="https://github.com/user-attachments/assets/d8d10240-ea9d-458c-b4a3-892532b6f3eb" alt="" /></a></h1>
</div>
</td>
</tr>
</tbody>
</table>

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
  * https://serverfault.com/questions/1005761/what-does-error-cycle-means-in-terraform
  * https://medium.com/vmacwrites/tools-to-visualize-your-terraform-plan-d421c6255f9f
  * https://www.graphviz.org/download/

```
terraform graph -draw-cycles | dot -Tpng -o graph.png
```

![graph](https://github.com/user-attachments/assets/77bfab00-c255-42fa-9384-d222e9e692ee)


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
