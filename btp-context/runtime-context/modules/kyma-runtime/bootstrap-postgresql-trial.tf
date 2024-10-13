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

output "cluster_ips" {
 value = data.local_file.cluster_ips.content
}

# https://registry.terraform.io/providers/massdriver-cloud/jq/latest/docs/data-sources/query
# https://stackoverflow.com/a/74681482
#
data "jq_query" "allow_access" {
   depends_on = [terraform_data.egress_ips]

   data = jsonencode({
   		"allow_access" : "${data.local_file.cluster_ips.content}" 
   	})
   query = " .allow_access | gsub(\"[ ]\"; \", \") | gsub(\"[\\n]\"; \"\") "
}

# https://registry.terraform.io/providers/massdriver-cloud/jq/latest/docs/data-sources/query
#
data "jq_query" "postgresql" {
   depends_on = [terraform_data.egress_ips]

   data = jsonencode({
	    "apiVersion": "services.cloud.sap.com/v1",
	    "kind": "ServiceInstance",
	    "metadata": {
	        "name": "postgresql",
	        "namespace" : "quovadis-btp"
	    },
	    "spec": {
	        "serviceOfferingName": "postgresql-db",
	        "servicePlanName": "trial",
	        "parameters": {
	            "region": "us-east-1",
	            "allow_access": data.jq_query.allow_access.result
	        }
	    }	
	})

//   query = " .spec.parameters |= . + { region: .region, allow_access: \"${data.jq_query.allow_access.result}\" | fromjson }  "
   query = " .spec.parameters |= . + { region: .region, allow_access: \"${local.allow_access}\" }  "
}

locals {
	depends_on = [terraform_data.egress_ips]

	postgresql = data.jq_query.postgresql.result
	allow_access = jsondecode(data.jq_query.allow_access.result) // 188.214.8.0/24,13.105.117.0/24,13.105.49.0/24

	postgresql_binding = jsonencode({
	    "apiVersion": "services.cloud.sap.com/v1",
	    "kind": "ServiceBinding",
	    "metadata": {
	        "name": "postgresql-binding",
	        "namespace" : "quovadis-btp"
	    },
	    "spec": {
	        "serviceInstanceName": "postgresql",
	        "secretName": "postgresql-binding-secret"
	    }
	})

   postgresql_instance = jsonencode({
      "apiVersion": "services.cloud.sap.com/v1",
      "kind": "ServiceInstance",
      "metadata": {
          "name": "postgresql",
          "namespace" : "quovadis-btp"
      },
      "spec": {
          "serviceOfferingName": "postgresql-db",
          "servicePlanName": "trial",
          "parameters": {
              "region": "us-east-1",
              "allow_access": data.jq_query.allow_access.result
          }
      } 
  })


}

output "allow_access" {
	value = local.allow_access
}

output "postgresql" {
	value = yamlencode(jsondecode(local.postgresql))
}

output "postgresql-binding" {
	value = yamlencode(jsondecode(local.postgresql_binding))
}

output "postgresql-instance" {
  value = yamlencode(jsondecode(local.postgresql_instance))
}

resource "kubectl_manifest" "postgresql-trial" {
    count     = var.BTP_POSTGRESQL_DRY_RUN ? 0 : 1
    yaml_body = yamlencode(jsondecode(local.postgresql))

    depends_on = [terraform_data.bootstrap-kymaruntime-bot, terraform_data.egress_ips]

    lifecycle {
      ignore_changes = all
    }    
}


resource "kubectl_manifest" "postgresql-trial-binding" {
    count     = var.BTP_POSTGRESQL_DRY_RUN ? 0 : 1
    yaml_body = yamlencode(jsondecode(local.postgresql_binding))

    depends_on = [terraform_data.bootstrap-kymaruntime-bot, terraform_data.egress_ips]

    lifecycle {
      ignore_changes = all
    }    
}

/*  
resource "btp_subaccount_entitlement" "postgresql" {
  subaccount_id = data.btp_subaccount.context.id
  service_name  = "postgresql-db"
  plan_name     = "trial"
  amount        = 1
}
*/



resource "terraform_data" "httpbin" {
  depends_on = [terraform_data.egress_ips]

/*
  triggers_replace = {
    always_run = "${timestamp()}"
  }
*/

  triggers_replace = [
        btp_subaccount_environment_instance.kyma,
        terraform_data.kubectl_getnodes
  ]

 provisioner "local-exec" {
   interpreter = ["/bin/bash", "-c"]
   on_failure = continue
   command = <<EOF
     (
    KUBECONFIG=kubeconfig-headless.yaml
    NAMESPACE=montypython
    NAMESPACE2=quovadis-btp

    set -e -o pipefail
    HTTPBIN=$(./kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE get deployment httpbin --ignore-not-found)
    if [ "$HTTPBIN" = "" ]
    then
      ./kubectl create ns $NAMESPACE --kubeconfig $KUBECONFIG --dry-run=client -o yaml | ./kubectl apply --kubeconfig $KUBECONFIG -f -
      ./kubectl label namespace $NAMESPACE istio-injection=enabled --kubeconfig $KUBECONFIG
      ./kubectl -n $NAMESPACE create -f https://raw.githubusercontent.com/quovadis-btp/istio/refs/heads/master/samples/httpbin/httpbin.yaml --kubeconfig $KUBECONFIG

      while [ "$(./kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE get deployment httpbin --ignore-not-found)" = "" ]
      do 
        echo "no deployment httpbin"
        sleep 1
      done      
    fi

    HTTPBIN=$(./kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE rollout status deployment httpbin --timeout 5m)
    echo $HTTPBIN 

     )
   EOF
 }
}

# https://www.gnu.org/software/gawk/manual/html_node/Print-Examples.html
# https://stackoverflow.com/questions/40321035/remove-escape-sequence-characters-like-newline-tab-and-carriage-return-from-jso
#     jq -r '.spec.parameters.allow_access | gsub("[\\n\\t]"; ";") '
resource "terraform_data" "egress_ips" {
  depends_on = [terraform_data.provider_context]

/*
  triggers_replace = {
    always_run = "${timestamp()}"
  }
*/

  triggers_replace = [
        btp_subaccount_environment_instance.kyma,
        terraform_data.kubectl_getnodes
  ]

  input = nonsensitive(
    jsonencode({
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
              "allow_access": ""
          }
      } 
    })
  )  

 provisioner "local-exec" {
   interpreter = ["/bin/bash", "-c"]
   //on_failure = continue
   command = <<EOF
     (
    KUBECONFIG=kubeconfig-headless.yaml
    NAMESPACE=quovadis-btp
     
    set -e -o pipefail ;\
    ZONES=$(./kubectl get nodes --kubeconfig $KUBECONFIG -o 'custom-columns=NAME:.metadata.name,REGION:.metadata.labels.topology\.kubernetes\.io/region,ZONE:.metadata.labels.topology\.kubernetes\.io/zone' -o json | jq -r '.items[].metadata.labels["topology.kubernetes.io/zone"]' | sort | uniq)
    echo $ZONES

    for zone in $ZONES; do
    overrides="{ \"apiVersion\": \"v1\", \"spec\": { \"nodeSelector\": { \"topology.kubernetes.io/zone\": \"$zone\" } } }"
    echo | ./kubectl run --kubeconfig $KUBECONFIG --timeout=5m -i --tty curl --image=everpeace/curl-jq --restart=Never  --overrides="$overrides" --rm --command -- curl -s http://ifconfig.me/ip >> temp_ips.txt 2>/dev/null
    sleep 2
    done
    cat temp_ips.txt
    CLUSTER_IPS=$(awk '{gsub("pod \"curl\" deleted", "", $0); print}' temp_ips.txt)
    rm temp_ips.txt
    
    echo $CLUSTER_IPS > cluster_ips.txt
    
    # https://stackoverflow.com/questions/40321035/remove-escape-sequence-characters-like-newline-tab-and-carriage-return-from-jso
    #
    IPS=$(echo $CLUSTER_IPS | jq -r -R '. | gsub("[ ]"; ", ") ')

    PostgreSQL='${self.input}'
    echo $(jq -r '.' <<< $PostgreSQL)
    echo $PostgreSQL | jq -r --arg ips "$IPS" '.spec.parameters |= . + { region: .region, allow_access: $ips }'

     )
   EOF
 }
}

output "egress_ips" {
  value = terraform_data.egress_ips.output
}
