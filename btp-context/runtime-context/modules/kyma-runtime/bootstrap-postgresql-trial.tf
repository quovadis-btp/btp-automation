/*
---
apiVersion: services.cloud.sap.com/v1
kind: ServiceInstance # kubernetes api resource for creating service instance
metadata:
  name: postgresql #<instance name> # replace with instance name
  #namespace: postgresql #<namespace> # replace with the namespace where the resource should be created
spec:
  serviceOfferingName: postgresql-db # service name
  servicePlanName: trial #development # service plan
  parameters: # list of parameters exposed via broker
    region: us-east-1
    allow_access: "52.6.160.101" #<ip-address1>,<ip-address2>,... # comma-separated list of IP addresses, IP CIDRs and CF Domains
---
apiVersion: services.cloud.sap.com/v1
kind: ServiceBinding
metadata:
  name: postgresql-binding # name of the service key
spec:
  serviceInstanceName: postgresql # instance for which you want to create the service key
  secretName: postgresql-binding-secret # secret name that will be created
*/

// https://stackoverflow.com/questions/57454591/how-can-i-load-input-data-from-a-file-in-terraform
// https://stackoverflow.com/questions/77882605/using-resource-local-file-in-terraform-with-atlantis
// https://containersolutions.github.io/terraform-examples/examples/local/local.html
// https://stackoverflow.com/questions/67937425/terraform-how-to-make-the-local-file-resource-to-be-recreated-with-every-te
//
data "local_file" "cluster_ips" {
  depends_on = [terraform_data.egress_ips]
  
  filename = "cluster_ips.txt" 
}


locals {
	depends_on = [terraform_data.egress_ips]

	// https://stackoverflow.com/a/74681482
	
	postgresql = jsonencode({
	    "apiVersion": "services.cloud.sap.com/v1",
	    "kind": "ServiceInstance",
	    "metadata": {
	        "name": "postgresql"
	    },
	    "spec": {
	        "serviceOfferingName": "postgresql-db",
	        "servicePlanName": "trial",
	        "parameters": {
	            "region": "us-east-1",
	            "allow_access": ${data.local_file.cluster_ips.content}  //"52.6.160.101"
	        }
	    }	
	})

	postgresql_binding = jsonencode({
	    "apiVersion": "services.cloud.sap.com/v1",
	    "kind": "ServiceBinding",
	    "metadata": {
	        "name": "postgresql-binding"
	    },
	    "spec": {
	        "serviceInstanceName": "postgresql",
	        "secretName": "postgresql-binding-secret"
	    }
	})

}

output "postgresql" {
	value = jsondecode(local.postgresql)
}
