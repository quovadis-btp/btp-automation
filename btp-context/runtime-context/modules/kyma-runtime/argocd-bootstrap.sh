#!/bin/bash

ARGOCD_NAMESPACE=argocd
ARGOCD_SERVICEACCOUNT=demo-argocd-manager
NAMESPACE=quovadis-btp
KUBECONFIG=kubeconfig-headless.yaml
SHOOT_NAME=$(./kubectl config current-context --kubeconfig $KUBECONFIG )


# create a dedicated namespace for argocd related configurations
./kubectl create ns $ARGOCD_NAMESPACE --kubeconfig $KUBECONFIG --dry-run=client -o yaml | ./kubectl apply --kubeconfig $KUBECONFIG -f -
# Create a service account to be used by argocd
./kubectl -n $ARGOCD_NAMESPACE create serviceaccount $ARGOCD_SERVICEACCOUNT --kubeconfig $KUBECONFIG --dry-run=client -o yaml | ./kubectl apply --kubeconfig $KUBECONFIG -f -
# create a cluster rolebinding for argocd service account
./kubectl create clusterrolebinding $ARGOCD_SERVICEACCOUNT --serviceaccount $ARGOCD_NAMESPACE:$ARGOCD_SERVICEACCOUNT --clusterrole cluster-admin --kubeconfig $KUBECONFIG --dry-run=client -o yaml | ./kubectl apply --kubeconfig $KUBECONFIG -f -

./kubectl create ns $NAMESPACE --kubeconfig $KUBECONFIG --dry-run=client -o yaml | ./kubectl apply --kubeconfig $KUBECONFIG -f -
./kubectl label namespace $NAMESPACE istio-injection=enabled --kubeconfig $KUBECONFIG

./argocd --config argocd_config.json cluster add $SHOOT_NAME --service-account $ARGOCD_SERVICEACCOUNT --system-namespace $ARGOCD_NAMESPACE --namespace $NAMESPACE --kubeconfig $KUBECONFIG
./argocd --config argocd_config.json app list
