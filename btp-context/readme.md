
Business Landscape Automation
==========


<table style="width: 100%; border-collapse: collapse; background-color: #f5f5f5;" border="1">
<tbody>
<tr style="height: 193px;">
<td style="width: 71.6%; height: 193px;">
<div>
<h1><a href="https://github.com/kyma-project/kyma/issues/18666#issuecomment-2082901529"><img class="aligncenter" src="https://github.com/user-attachments/assets/e4c7b90e-eaee-4461-bc1d-7325e0868518" alt="" /></a></h1>
</div>
</td>
</tr>
</tbody>
</table>

Likewise, driving a car, seldom requires opening the bonnet, business users focus on functionality.  

The btp contexts abstraction lays ground for a generic receipe that makes the provisioning and houskeeping of a BTP landscape with kyma runtime environment and BTP backing services a rather pleasant experience for the business users.  

To make this receipe a reality, I have coined a term of a _depleted_ runtime environment that comprises one or several kyma clusters accompanied with a restricted set of BTP services (for instance, a _depleted_ environment may not need to have the XSUAA service entitlement.)

However, all the kernel and business BTP services are available in a dedicated provider context (a provider subaccount) and are mereley referenced from kyma clusters (via a service sharing mechanism).  

This makes it possible for each kyma cluster to be torn down, detached, (re-)attached to a provider context.  

Additionally, a provider can be located in a different BTP landscape (with a different global account and/or in different BTP region (data center) as well).  

Or, even one could have the provider implemented with either a hybrid or a foreign, non-BTP landscape.  
For instance, a provider context could be implemented with other hyperscaler's services or with a mix of BTP and multicloud hyperscalers services.

Furthermore, this approach allows for _location and data center transparency_ with the _intrinsic failover_ between runtime and provider(s) contexts.  



Introduction to btp contexts
=============



<table style="width: 100%; border-collapse: collapse; background-color: #f5f5f5;" border="1">
<tbody>
<tr style="height: 193px;">
<td style="width: 71.6%; height: 193px;">
<div>
<h1><a href=""><img class="aligncenter" src="https://github.com/user-attachments/assets/299f0113-3ba6-47de-86b2-9bbfa2ad4e3f" alt="" /></a></h1>
</div>
</td>
</tr>
</tbody>
</table>

BTP contexts are logical entities defined to host and implement various infrastructure contexts, namely bootstrap, runtime, provider and consumer.  

The main idea behind the contexts is the ability to combine and maintain resources from multiple global accounts with their subaccounts across different regions and break free from 
the rigidity of the cloud foundry runtime org structure.

In a nutshell, the contexts are declarative entities, defined as terraform scripts, eventually orchestrated by CI/CD pipelines.  

<table style="width: 100%; border-collapse: collapse; background-color: #ebf8ff;" border="1">
<tbody>
<tr>
<td style="width: 100%;"><details open="open"><summary>Table of Contents</summary>

<ol>
 	<li><a href="#btp-automation">Bootstrap toolkit for business users.</a></li>
<ol>
 	<li><a href="#runtime-context">"Depleted" runtime environment.</a></li>
 	<li><a href="#provider-context">Provider Context</a>.</li>
 	<li><a href="#main-benefits">Advantages of this approach</a>.</li>
 	<li><a href="#enhanced-features">Enhanced Features.</a></li>
 	<li><a href="#overall-benefits">Overall Benefits</a>.</li>
 	<li><a href="#things-to-consider">Things to consider</a>.</li>
</ol>

 <li><a href="#terraform-automation">Terraform automation.</a></li>
<ol>
 	<li><a href="#terraform-visual-cli">terraform visual cli.</a></li>
 	<li><a href="#terraform-graph">terraform graph</a>.</li>
 	<li><a href="#terraform-k8s-backed">terraform kubernetes backend</a>.</li>
  <li><a href="#terraform-k8s-dynamic-credentials">Dynamic Credentials with the TF Kubernetes and Helm providers</a>.</li> 
</ol>

 <li><a href="#references">Useful links.</a></li>
</ol>

</details></td>
</tr>
</tbody>
</table>


<h2 id="btp-automation">1. Bootstrap toolkit for business users.</h2>  

The value proposition behind a "depleted" runtime environment concept, in particular in the context of SAP Business Technology Platform (BTP),  
is a more flexible and efficient approach to managing BTP landscapes, particularly those using Kyma runtime.   

Let me summarize and expand on the concept's main ideas:

<h3 id="runtime-context">1.1 "Depleted" Runtime Environment.</h3>  

  * Consists of one or more Kyma clusters
  * Has a limited set of BTP services directly associated
  * Lacks some standard services (e.g., XSUAA) in the immediate environment

<h3 id="provider-context">1.2 Provider Context.</h3>  

  * A dedicated subaccount containing all necessary kernel and business BTP services
  * Services in the provider context are referenced from Kyma clusters via service sharing mechanism

<h3 id="main-benefits">1.3 Advantages of this approach.</h3>  

  * Flexibility: Kyma clusters can be easily torn down, detached, or re-attached to provider contexts
  * Cross-landscape compatibility: Provider can be in a different BTP landscape or global account
  * Multi-region support: Provider can be in a different BTP region (data center)
  * Hybrid/Multi-cloud potential: Provider could be implemented using non-BTP services or a mix of BTP and other hyperscaler services

<h3 id="enhanced-features">1.4 Enhanced Features.</h3>  

  * Location and data center transparency
  * Intrinsic failover between runtime and provider contexts

<h3 id="overall-benefits">1.5 Overall benefits</h3>  

This approach seems to offer several benefits:

  * Simplified Management: By centralizing core services in a provider context, you reduce the complexity of individual Kyma clusters.
  * Resource Efficiency: "Depleted" environments likely consume fewer resources, potentially reducing costs.
  * Flexibility and Scalability: The ability to easily attach/detach Kyma clusters from provider contexts allows for more dynamic scaling and reconfiguration.
  * Improved Disaster Recovery: The intrinsic failover capability enhances system resilience.
  * Multi-Cloud and Hybrid Cloud Support: This architecture seems well-suited for complex, distributed environments spanning multiple cloud providers or on-premises/cloud hybrid setups.

<h3 id="things-to-consider">1.6 Things to consider</h3>  

To fully realize this concept, one'd likely need to consider:

  * Service Discovery and Routing: Ensuring efficient communication between "depleted" environments and provider contexts.
  * Security: Maintaining proper access controls and data protection across distributed components.
  * Monitoring and Observability: Implementing comprehensive monitoring across the entire landscape.
  * Consistency: Ensuring consistent behavior and performance across different provider implementations.
  * Documentation and Training: As this is a novel approach, clear documentation and training for operations teams would be crucial.

This approach aligns well with modern cloud-native architectures and microservices principles, potentially offering significant advantages in terms of flexibility, efficiency, and scalability for BTP landscapes. It would be particularly beneficial for organizations with complex, multi-region, or multi-cloud requirements.

#### References  

  * [Seamless deployment of SaaS provider applications to kyma environments](https://github.com/kyma-project/kyma/issues/18666)


<h2 id="terraform-automation">2. Terraform automation.</h2>  

Terraform is a popular declarative CaC tool that allows you to describe and orchestrate infrastructure landscapes in the form of code.  
It allows to plan, apply and maintain the desired state of our defined btp contexts, laying the bricks towards business landscape automation - our ultimate goal.    

This is made possible by a [rich ecosystem of providers](https://registry.terraform.io/browse/providers).  
Providers are a logical abstraction of an upstream API. They are responsible for understanding API interactions and exposing resources.  

For instance, the SAP BTP [terraform provider](https://registry.terraform.io/providers/SAP/btp/latest/docs) is leveraging the server side BTP CLI API.  
Additionally, each terraform provider may have its own ecosystem of modules, self-contained packages of Terraform configurations that are managed as a group.  
For instance, for sap btp: https://registry.terraform.io/providers/SAP/btp/latest


<table style="width: 100%; border-collapse: collapse; background-color: #f5f5f5;" border="1">
<tbody>
<tr style="height: 193px;">
<td style="width: 71.6%; height: 193px;">
<div>
<h1><a href="https://registry.terraform.io/providers/SAP/btp/latest"><img class="aligncenter" src="https://github.com/user-attachments/assets/7babdaf3-8255-4496-b7a5-bc2d816c7348" alt="" /></a></h1>
</div>
</td>
</tr>
</tbody>
</table>

<h3 id="terraform-visual-cli">2.1 terraform visual cli</h3>  

```
terraform plan -var-file="89982f73trial/btp-trial.tfvars" -out=plan.out
terraform show -json plan.out > plan.json
terraform-visual --plan plan.json
open terraform-visual-report/index.html
```


<table style="width: 100%; border-collapse: collapse; background-color: #f5f5f5;" border="1">
<tbody>
<tr style="height: 193px;">
<td style="width: 71.6%; height: 193px;">
<div>
<h1><a href="https://www.npmjs.com/package/@terraform-visual/cli#terraform-visual-cli"><img class="aligncenter" src="https://github.com/user-attachments/assets/e403fb26-f470-4409-88b2-6188b301f1d3" alt="" /></a></h1>
</div>
</td>
</tr>
</tbody>
</table>

#### References

  * https://www.npmjs.com/package/@terraform-visual/cli#terraform-visual-cli  
  * https://github.com/hieven/terraform-visual?tab=readme-ov-file
  * https://developer.hashicorp.com/terraform/tutorials/state/refresh


<h3 id="terraform-graph">2.2 terraform graph</h3>  


```
terraform graph --help
terraform graph -type=plan | dot -Tpng -o graph.png
```


<table style="width: 100%; border-collapse: collapse; background-color: #f5f5f5;" border="1">
<tbody>
<tr style="height: 193px;">
<td style="width: 71.6%; height: 193px;">
<div>
<h1><a href="https://serverfault.com/questions/1005761/what-does-error-cycle-means-in-terraform"><img class="aligncenter" src="https://github.com/user-attachments/assets/9ac7fb0a-1b71-4ecb-a160-b52d5b9d4c63" alt="" /></a></h1>
</div>
</td>
</tr>
</tbody>
</table>

```
terraform graph -draw-cycles | dot -Tpng -o graph.png
```


<table style="width: 100%; border-collapse: collapse; background-color: #f5f5f5;" border="1">
<tbody>
<tr style="height: 193px;">
<td style="width: 71.6%; height: 193px;">
<div>
<h1><a href="https://serverfault.com/questions/1005761/what-does-error-cycle-means-in-terraform"><img class="aligncenter" src="https://github.com/user-attachments/assets/417d9047-db74-496f-b19b-5b88c8185f98" alt="" /></a></h1>
</div>
</td>
</tr>
</tbody>
</table>

#### References

  * https://serverfault.com/questions/1005761/what-does-error-cycle-means-in-terraform
  * https://medium.com/vmacwrites/tools-to-visualize-your-terraform-plan-d421c6255f9f
  * https://www.graphviz.org/download/


<h3 id="terraform-k8s-backed">2.3. Keeping the terraform state in a Kubernetes Secret.</h3>

> A backend defines where Terraform stores its state data files.

> Terraform uses persisted state data to keep track of the resources it manages. Most non-trivial Terraform configurations either integrate with HCP Terraform or use a backend to store state remotely. This lets multiple people access the state data and work together on that collection of infrastructure resources.

I've chosen the kubernetes secrets as a terraform backend.  I did it with a managed kyma cluster.  

```
kubectl get secret tfstate-default-state-89982f73trial  -n tf-runtime-context --kubeconfig ~/.kube/kubeconfig--c-***-default.yaml -o jsonpath="{.data.tfstate}" | base64 -d | gzip -d > tfstate.json
```

<h3 id="terraform-workspaces">2.4. Working with terraform workspaces.</h3>

  * List and select a working workspace before running terraform init and apply commands
    
```
terraform workspace list
  provider-context-1afe5b3btrial
  provider-context-41bb3a1e-2c13-454e-976f-d9734acad3c4
  provider-context-89ebab58trial
  provider-context-pxxxxxxx
* provider-context-quovadis-anywhere
  provider-context-rthxxxxx
```
  * run terraform apply against a specific set of input values

```
terraform apply -var-file=kyma-adoption-live/btp-live.tfvars -input=false -auto-approve
```

#### References

  * https://pet2cattle.com/2022/04/terraform-remote-state-kubernetes

<h3 id="terraform-k8s-dynamic-credentials">2.5. Dynamic Credentials with the Kubernetes and Helm providers.</h3>

This is only available if using TFC (HCP) to run your automation pipeline as described in the following article:
  * [Dynamic Credentials with the Kubernetes and Helm providers](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/kubernetes-configuration#configure-hcp-terraform)

As we are able to gain a headless access to a kyma cluster we can leverage the cluster's oidc shoot extension to create an OIDC provider with TF HCP acting as identity provider.  


```
shoot_info = {
        extensions        = "shoot-auditlog-service,shoot-cert-service,shoot-dns-service,shoot-lakom-service,shoot-networking-problemdetector,shoot-oidc-service"
    }
```

<table style="width: 100%; border-collapse: collapse; background-color: #f5f5f5;" border="1">
<tbody>
<tr style="height: 193px;">
<td style="width: 71.6%; height: 193px;">
<div>
<h1><a href="https://www.scalr.com/blog/top-20-terraform-providers"><img class="aligncenter" src="https://github.com/user-attachments/assets/cac7ec39-12f9-46fb-aad7-07e6dd5e1900" alt="" /></a></h1>
</div>
</td>
</tr>
</tbody>
</table>

During the TFC apply run the following variable will be populate with the kube token, namely

```
// https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/kubernetes-configuration#configure-hcp-terraform
//
variable "tfc_kubernetes_dynamic_credentials" {
  description = "Object containing Kubernetes dynamic credentials configuration"
  type = object({
    default = object({
      token_path = string
    })
    aliases = map(object({
      token_path = string
    }))
  })
}

output "kube_token" {
  sensitive = true
  value = file(var.tfc_kubernetes_dynamic_credentials.default.token_path)
}

```

with both kubernetes and kubectl providers blocks as follows:

```
provider "kubernetes" {

  host                   = try(yamldecode(data.tfe_outputs.current-runtime-context.values.headless-kubeconfig).clusters.0.cluster.server, local.kubeconfig.clusters[0].cluster.server)

  cluster_ca_certificate = base64decode(try(yamldecode(data.tfe_outputs.current-runtime-context.values.headless-kubeconfig).clusters.0.cluster.certificate-authority-data, local.kubeconfig.clusters[0].cluster.certificate-authority-data))

  token = try(file(var.tfc_kubernetes_dynamic_credentials.default.token_path), local.kubeconfig.users[0].user.token)
}

provider "kubectl" {

  host                   = try(yamldecode(data.tfe_outputs.current-runtime-context.values.headless-kubeconfig).clusters.0.cluster.server, local.kubeconfig.clusters[0].cluster.server)

  cluster_ca_certificate = base64decode(try(yamldecode(data.tfe_outputs.current-runtime-context.values.headless-kubeconfig).clusters.0.cluster.certificate-authority-data, local.kubeconfig.clusters[0].cluster.certificate-authority-data))

  token = try(file(var.tfc_kubernetes_dynamic_credentials.default.token_path), local.kubeconfig.users[0].user.token)
   load_config_file       = false

}
```


```
// https://developer.hashicorp.com/terraform/cloud-docs/run/run-environment#environment-variables
//
variable "TFC_WORKSPACE_NAME" {
  // HCP Terraform automatically injects the following environment variables for each run. 
  description = "The name of the workspace used in this run."
  type        = string
}

variable "TFC_PROJECT_NAME" {
  // HCP Terraform automatically injects the following environment variables for each run. 
  description = "The name of the project used in this run."
  type        = string
}

variable "TFC_WORKSPACE_SLUG" {
  // HCP Terraform automatically injects the following environment variables for each run. 
  description = "The slug consists of the organization name and workspace name, joined with a slash."
  type        = string
}

// organization:<MY-ORG-NAME>:project:<MY-PROJECT-NAME>:workspace:<MY-WORKSPACE-NAME>:run_phase:<plan|apply>.
locals {
  organization_name = split("/", var.TFC_WORKSPACE_SLUG)[0]
  user_plan = "organization:${local.organization_name}:project:${var.TFC_PROJECT_NAME}:workspace:${var.TFC_WORKSPACE_NAME}:run_phase:plan"
  user_apply = "organization:${local.organization_name}:project:${var.TFC_PROJECT_NAME}:workspace:${var.TFC_WORKSPACE_NAME}:run_phase:apply"
}

output "user_plan" {
  value = local.user_plan
}

output "user_apply" {
  value = local.user_apply
}

data "tfe_workspace" "current-runtime-context" {
  name         = var.TFC_WORKSPACE_NAME
  organization = "${local.organization_name}"
}

output "workspace_id" {
  value = data.tfe_workspace.current-runtime-context.id
}

// https://developer.hashicorp.com/terraform/language/terraform#tf_cloud_organization
// https://developer.hashicorp.com/terraform/language/terraform#tf_workspace
//
data "tfe_outputs" "current-runtime-context" {
  organization = "${local.organization_name}"
  workspace    = var.TFC_WORKSPACE_NAME
}
```

<h2 id="references">3. Useful links.</h2>

<table style="width: 100%; border-collapse: collapse; background-color: #f5f5f5;" border="1">
<tbody>
<tr style="height: 193px;">
<td style="width: 71.6%; height: 193px;">
<div>
<h1><a href="https://www.scalr.com/blog/top-20-terraform-providers"><img class="aligncenter" src="https://github.com/user-attachments/assets/26a0f1eb-48aa-4c21-8bc3-2b9d7b57b2f0" alt="" /></a></h1>
</div>
</td>
</tr>
</tbody>
</table>

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
