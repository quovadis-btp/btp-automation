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

locals {
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
	            "allow_access": "52.6.160.101"
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
