# https://pages.github.tools.sap/apm/docs/installation/kubernetes/#deployment
# https://pages.github.tools.sap/apm/docs/installation/kubernetes/#deploy-dynatrace-operator-with-cloud-native-full-stack-injection
#

locals {

  apiToken = var.apiToken
  dataIngestToken = var.dataIngestToken
  apiUrl = var.apiUrl
  
}

data "http" "dynakube" {

  url = "https://raw.githubusercontent.com/Dynatrace/dynatrace-operator/v1.2.2/assets/samples/dynakube/v1beta2/cloudNativeFullStack.yaml"

  lifecycle {
    postcondition {
      condition     = contains([200, 201, 204], self.status_code)
      error_message = "Status code invalid"
    }
  }  
}


resource "local_sensitive_file" "dynakube" {

  filename = "dynakube.json"
  content  = jsonencode(yamldecode(data.http.dynakube.response_body))
}

data "jq_query" "dynakube" {

   data = jsonencode(yamldecode(data.http.dynakube.response_body))
   query = ".spec |= . + { apiUrl: ${local.apiUrl}, tokens: 'dynakube' }"
}

output "dynakube" {
  value = jsondecode(data.jq_query.dynakube.result)
}

resource "terraform_data" "bootstrap-dynatrace" {
  depends_on = [terraform_data.bootstrap-kymaruntime-bot]

  triggers_replace = [
        terraform_data.kubectl_getnodes
  ]

  # the input becomes a definition of an OpenIDConnect provider as a non-sensitive json encoded string 
  #
  input = [ nonsensitive(local.apiToken), nonsensitive(local.dataIngestToken), nonsensitive(local.apiUrl) ]

 # https://discuss.hashicorp.com/t/resource-attribute-json-quotes-getting-stripped/45752/4
 # https://stackoverflow.com/questions/75255995/how-to-echo-a-jq-json-with-double-quotes-escaped-with-backslash
 #
 provisioner "local-exec" {
   interpreter = ["/bin/bash", "-c"]
   command = <<EOF
     (
    KUBECONFIG=kubeconfig-headless.yaml
    NAMESPACE=dynatrace
    set -e -o pipefail ;\
    
    API_TOKEN='${self.input[0]}'
    echo $API_TOKEN
    DATA_INGEST_TOKEN='${self.input[1]}'
    echo $DATA_INGEST_TOKEN
    DT_ENVIRONMENT_API_URL='${self.input[2]}'
    echo $DT_ENVIRONMENT_API_URL

    DYNAKUBE=$(curl -o dynakube.yaml https://raw.githubusercontent.com/Dynatrace/dynatrace-operator/v1.2.2/assets/samples/dynakube/v1beta2/cloudNativeFullStack.yaml)

    ./kubectl wait --for condition=established -n $NAMESPACE crd dynakubes.dynatrace.com --timeout=300s --kubeconfig $KUBECONFIG
    crd=$(./kubectl get crd -n $NAMESPACE dynakubes.dynatrace.com --kubeconfig $KUBECONFIG -ojsonpath='{.metadata.name}' --ignore-not-found)
    ./kubectl wait --for condition=established -n $NAMESPACE crd edgeconnects.dynatrace.com --timeout=300s --kubeconfig $KUBECONFIG
    crd2=$(./kubectl get crd -n $NAMESPACE edgeconnects.dynatrace.com --kubeconfig $KUBECONFIG -ojsonpath='{.metadata.name}' --ignore-not-found)

    if [ "$crd" != "dynakubes.dynatrace.com" ] || [ "$crd2" != "edgeconnects.dynatrace.com" ]
    then
      ./kubectl create ns $NAMESPACE --kubeconfig $KUBECONFIG --dry-run=client -o yaml | ./kubectl apply --kubeconfig $KUBECONFIG -f -
      ./kubectl label namespace $NAMESPACE istio-injection=disabled --overwrite --kubeconfig $KUBECONFIG
      echo | ./kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/download/v1.2.2/kubernetes.yaml --kubeconfig $KUBECONFIG
      echo | ./kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/download/v1.2.2/kubernetes-csi.yaml --kubeconfig $KUBECONFIG

      echo | ./kubectl -n dynatrace wait pod --for=condition=ready --selector=app.kubernetes.io/name=dynatrace-operator,app.kubernetes.io/component=webhook --timeout=300s --kubeconfig $KUBECONFIG

      echo | ./kubectl -n dynatrace create secret generic dynakube --from-literal="apiToken=$API_TOKEN" --from-literal="dataIngestToken=$DATA_INGEST_TOKEN" --from-literal="apiurl=$DT_ENVIRONMENT_API_URL" --kubeconfig $KUBECONFIG

    else
      echo $crd
      echo $crd2
    fi

     )
   EOF
 }
}