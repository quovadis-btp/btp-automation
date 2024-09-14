BTP landscapes automation. Applying context semantics.
====================

The below screenshots depict the btp real estate orchestrated in the runtime context.  
As depicted below, the kyma runtime environment evolves in a depleted context where all the required btp services are sources from provider contexts.  


<table style="width: 100%; border-collapse: collapse; background-color: #f5f5f5;" border="1">
<tbody>
<tr style="height: 193px;">
<td style="width: 71.6%; height: 193px;">
<div>
<h1><a href=""><img class="aligncenter" src="https://github.com/user-attachments/assets/5e41e629-be42-4e65-a9bf-c76d8f58ea60" alt="" /></a></h1>
</div>
<div>
<h1><a href=""><img class="aligncenter" src="https://github.com/user-attachments/assets/41f830bf-d34d-49af-be07-5e070a7f7773" alt="" /></a></h1>
</div>  
</td>
</tr>
</tbody>
</table>

The bootstrap context has configured a custom SAP Cloud Identity service tenant as a global account wide platform IDP.  
This way there is no more need to rely on the global SAP ID.  

The runtime context is trusted with this custom SAP IAS tenant which is then used as both custom OIDC provider for the kyma cluster and as a bot OIDC provider with the OpenIDConnect kyma/gardener k8s extension.  

Eventually, a kyma environment is provisioned with a short lived token based kubeconfig which is used to bootstrap ArgoCD.  

PS. Both [cf](https://docs.cloudfoundry.org/concepts/architecture) and [k8s](https://phoenixnap.com/kb/understanding-kubernetes-architecture-diagrams) runtimes can be used jointly or seperately in their respective runtime contexts

## Destinations

These destinations are the entry endpoints to help manage the runtime context estate.  


<img width="1441" alt="image" src="https://github.com/user-attachments/assets/7d9cc274-6021-40c1-bb41-383ecdf237ae">
