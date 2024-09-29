# https://pages.github.tools.sap/apm/docs/installation/kubernetes/#deployment
# https://pages.github.tools.sap/apm/docs/installation/kubernetes/#deploy-dynatrace-operator-with-cloud-native-full-stack-injection
#

locals {

  apiToken = var.apiToken
  dataIngestToken = var.dataIngestToken
  apiUrl = var.apiUrl

  tokens = "dynakube" // the tokens name in dynakube.yaml must match the secret name
  name = "dynakube"

  version_tag = "v1.3.0" //"v1.2.2"
  
}

data "http" "dynakube" {
  depends_on = [btp_subaccount_environment_instance.kyma]

  url = "https://raw.githubusercontent.com/Dynatrace/dynatrace-operator/${local.version_tag}/assets/samples/dynakube/v1beta2/cloudNativeFullStack.yaml"

  lifecycle {
    postcondition {
      condition     = contains([200, 201, 204], self.status_code)
      error_message = "Status code invalid"
    }
  }  
}


resource "local_sensitive_file" "dynakube" {
   depends_on = [ data.http.dynakube ]

   filename = "dynakube.json"
   content  = jsonencode(yamldecode(data.http.dynakube.response_body))
}

locals {
  dynakube = jsonencode({

    "apiVersion": "dynatrace.com/v1beta2",
    "kind": "DynaKube",
    "metadata": {
        "name": "dynakube",
        "namespace": "dynatrace"
    },
    "spec": {
        "apiUrl": "https://ENVIRONMENTID.live.dynatrace.com/api",
        "metadataEnrichment": {
            "enabled": true
        },
        "oneAgent": {
            "cloudNativeFullStack": {
                "tolerations": [
                    {
                        "effect": "NoSchedule",
                        "key": "node-role.kubernetes.io/master",
                        "operator": "Exists"
                    },
                    {
                        "effect": "NoSchedule",
                        "key": "node-role.kubernetes.io/control-plane",
                        "operator": "Exists"
                    }
                ]
            }
        },
        "activeGate": {
            "capabilities": [
                "routing",
                "kubernetes-monitoring",
                "dynatrace-api"
            ],
            "resources": {
                "requests": {
                    "cpu": "500m",
                    "memory": "512Mi"
                },
                "limits": {
                    "cpu": "1000m",
                    "memory": "1.5Gi"
                }
            }
        }
    }

  })
}

data "jq_query" "dynakube" {
   depends_on = [ data.http.dynakube ]

   //data = jsonencode(yamldecode(data.http.dynakube.response_body))
   data = local.dynakube
   query = ".metadata |= . + {name: \"${local.name}\"  } | .spec |= . + { apiUrl: \"${local.apiUrl}\", tokens: \"${local.tokens}\" | .spec.activeGate.resources.requests |= . + { cpu: \"100\"} }"
}

locals {
  dynakube = data.jq_query.dynakube.result
}

output "dynakube" {
  value = jsondecode(local.dynakube)
}

# TODO: wait for the dynakube secret created and make dynatrace bootstrap optional
#
resource "terraform_data" "bootstrap-dynatrace" {
  //count            = var.BTP_DYNATRACE_DRY_RUN ? 0 : 1
  depends_on = [terraform_data.bootstrap-kymaruntime-bot]

  triggers_replace = [
        terraform_data.kubectl_getnodes
  ]

  # the input becomes a definition of an OpenIDConnect provider as a non-sensitive json encoded string 
  #
  input = [ 
      nonsensitive(local.apiToken), 
      nonsensitive(local.dataIngestToken), 
      nonsensitive(local.apiUrl), 
      nonsensitive(local.dynakube) 
  ]

 # https://discuss.hashicorp.com/t/resource-attribute-json-quotes-getting-stripped/45752/4
 # https://stackoverflow.com/questions/75255995/how-to-echo-a-jq-json-with-double-quotes-escaped-with-backslash
 #
 provisioner "local-exec" {
   interpreter = ["/bin/bash", "-c"]
   command = <<EOF
     (
    KUBECONFIG=kubeconfig-headless.yaml
    NAMESPACE=dynatrace
    SECRET_NAME=dynakube
    set -e -o pipefail ;\
    
    API_TOKEN='${self.input[0]}'
    echo $API_TOKEN
    
    DATA_INGEST_TOKEN='${self.input[1]}'
    echo $DATA_INGEST_TOKEN
    
    DT_ENVIRONMENT_API_URL='${self.input[2]}'
    echo $DT_ENVIRONMENT_API_URL

    DYNAKUBE='${self.input[3]}'
    echo $DYNAKUBE    

    crd=$(./kubectl get crd -n $NAMESPACE dynakubes.dynatrace.com --kubeconfig $KUBECONFIG -ojsonpath='{.metadata.name}' --ignore-not-found)
    crd2=$(./kubectl get crd -n $NAMESPACE edgeconnects.dynatrace.com --kubeconfig $KUBECONFIG -ojsonpath='{.metadata.name}' --ignore-not-found)

    if [ "$crd" != "dynakubes.dynatrace.com" ] || [ "$crd2" != "edgeconnects.dynatrace.com" ]
    then
      ./kubectl create ns $NAMESPACE --kubeconfig $KUBECONFIG --dry-run=client -o yaml | ./kubectl apply --kubeconfig $KUBECONFIG -f -
      ./kubectl label namespace $NAMESPACE istio-injection=disabled --overwrite --kubeconfig $KUBECONFIG
      echo | ./kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/download/${local.version_tag}/kubernetes.yaml --kubeconfig $KUBECONFIG
      echo | ./kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/download/${local.version_tag}/kubernetes-csi.yaml --kubeconfig $KUBECONFIG

      echo | ./kubectl wait --for condition=established -n $NAMESPACE crd dynakubes.dynatrace.com --timeout=300s --kubeconfig $KUBECONFIG
      echo | ./kubectl wait --for condition=established -n $NAMESPACE crd edgeconnects.dynatrace.com --timeout=300s --kubeconfig $KUBECONFIG

      while [ "$(./kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE get deployment dynatrace-operator --ignore-not-found)" = "" ]
      do 
        echo "deployments.apps - dynatrace-operator - not found"
        sleep 1
      done
      echo | ./kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE rollout status deployment dynatrace-operator --timeout 5m

      while [ "$(./kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE get deployment dynatrace-webhook --ignore-not-found)" = "" ]
      do 
        echo "deployments.apps - dynatrace-webhook - not found"
        sleep 1
      done
      echo | ./kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE rollout status deployment dynatrace-webhook --timeout 5m


      echo | ./kubectl -n $NAMESPACE create secret generic $SECRET_NAME --from-literal="apiToken=$API_TOKEN" --from-literal="dataIngestToken=$DATA_INGEST_TOKEN" --from-literal="apiurl=$DT_ENVIRONMENT_API_URL" --kubeconfig $KUBECONFIG --dry-run=client -o yaml | ./kubectl apply --kubeconfig $KUBECONFIG -f -

      echo | ./kubectl wait --for=create --timeout=180s secret/$SECRET_NAME -n $NAMESPACE --kubeconfig $KUBECONFIG

      echo $DYNAKUBE | ./kubectl apply --kubeconfig $KUBECONFIG -n $NAMESPACE -f - 
      while [ "$(./kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE get dynakube dynakube --ignore-not-found)" = "" ]
      do
        echo "dynakube - not found yet"
        sleep 1
      done

    else
      echo $crd
      echo $crd2
      echo | ./kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE get dynakube dynakube --ignore-not-found
    fi

     )
   EOF
 }
}