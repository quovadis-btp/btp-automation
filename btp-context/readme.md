btp contexts
=============

BTP contexts are a way of defining logical entities to host amd implement various contexts, namely bootstrap, runtime, provider and consumer.  

The main idea behind the contexts is to break silos of global account, subaccounts across different regions and break free from 
the rigidity of the cloud foundry runtime org structure.

In a nutshell, contexts are declarative entities, defined as terraform scripts and orchestrated by CI/CD pipelines. 

PS.
Both cf and k8s runtimes can be used jointly or seperately in their respective runtime contexts



[cf architecture](https://docs.cloudfoundry.org/concepts/architecture/)  
![image](https://github.com/user-attachments/assets/83226447-29d4-4ae4-89d7-47354154dd9f)


[k8s architecture](https://phoenixnap.com/kb/understanding-kubernetes-architecture-diagrams)  
![image](https://github.com/user-attachments/assets/649532ff-d679-4ea9-884d-c3fbd6edc528)

# References

  * https://spacelift.io/blog/terraform-best-practices
  * https://github.com/spacelift-io-blog-posts/Blog-Technical-Content/tree/master/terraform-best-practices
  * https://github.com/spacelift-io-blog-posts/Blog-Technical-Content
  * https://github.com/SAP-samples/btp-terraform-samples
  * https://registry.terraform.io/providers/SAP/btp/latest/docs
  * https://registry.terraform.io/providers/oboukili/argocd/latest/docs/data-sources/application
  * https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
  * https://developers.sap.com/tutorials/btp-terraform-get-started.html
  * https://github.com/aydin-ozcan/terraform-btp-sap-btp-entitlements/tree/main
  * 

  * https://spacelift.io/blog/terraform-ignore-changes
  * https://spacelift.io/blog/terraform-yaml#what-is-the-yamldecode-function-in-terraform
  * https://spacelift.io/blog/terraform-jsonencode#example-6-creating-iam-policies-using-jsonencode-function
  * https://developer.hashicorp.com/terraform/language/meta-arguments/for_each
  * https://spacelift.io/blog/terraform-count
  * https://stackoverflow.com/questions/75840856/how-to-trigger-resource-replacement-in-terraform-if-resource-atrtibute-changed
  * https://xebia.com/blog/replace-terraform-resources-based-on-other-changes-with-replace-triggered-by/
  * https://developer.hashicorp.com/terraform/language/resources/terraform-data
  * 