PostgreSQL on SAP BTP - Are you looking for official blog posts? Blog INDEX
======

https://community.sap.com/t5/technology-blogs-by-sap/postgresql-on-sap-btp-are-you-looking-for-official-blog-posts-blog-index/ba-p/13788533  

Blogs Index:

PostgreSQL - Understanding service entitlements and metrics
PostgreSQL - PostgreSQL is now available on the Kyma environment
PostgreSQL - How to deploy PostgreSQL on a Kyma environment
PostgreSQL - Connect to a PostgreSQL instance on a Kyma environment
PostgreSQL - Request an 'admin' user access valid for 'x' days
PostgreSQL - Activate (create) an extension via service API using Postman
PostgreSQL - Activate (create) an extension using pgAdmin tool
PostgreSQL - How to estimate the remaining storage free space?
PostgreSQL - Rotation of service keys and bindings due to Certificate CA expiration
🆕 Recently added  

PostgreSQL - (how-to) deploy and use pgAdmin web version
PostgreSQL - Instance sharing | 'reference' service plan

https://community.sap.com/t5/technology-blogs-by-sap/postgresql-on-sap-btp-instance-sharing-reference-service-plan/ba-p/13794791  



```sh
#!/bin/bash

for zone in $(kubectl get nodes -o 'custom-columns=NAME:.metadata.name,REGION:.metadata.labels.topology\.kubernetes\.io/region,ZONE:.metadata.labels.topology\.kubernetes\.io/zone' -o json | jq -r '.items[].metadata.labels["topology.kubernetes.io/zone"]' | sort | uniq); do
overrides="{ \"apiVersion\": \"v1\", \"spec\": { \"nodeSelector\": { \"topology.kubernetes.io/zone\": \"$zone\" } } }"
kubectl run -i --tty busybox --image=yauritux/busybox-curl --restart=Never  --overrides="$overrides" --rm --command -- curl http://ifconfig.me/ip >>/tmp/cluster_ips 2>/dev/null
done

awk '{gsub("pod \"busybox\" deleted", "", $0); print}' /tmp/cluster_ips
rm /tmp/cluster_ips
```

https://pages.github.tools.sap/cloudservices/docs/postgresql/Kubernetes-Consumption-User-Guide/  



```yaml
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
---
# Separate YAML for postgres instance sharing
# https://pages.github.tools.sap/cloudservices/docs/postgresql/Instance-Sharing/
apiVersion: services.cloud.sap.com/v1
kind: ServiceInstance
metadata:
  name: postgresql #btp-postgres-shared
  #namespace: btp-postgres
spec:
  serviceOfferingName: postgresql-db
  servicePlanName: trial
  externalName: btp-postgres-shared
  parameters:
      instance_shares:
          op: add
          values:
              - "6590ffff-f0f4-4629-b9ce-9911718836b9"
              # BTP subaccount ID
---
# sharing the btp postgres instance from the btp-postgres Kyma namespace
# https://pages.github.tools.sap/cloudservices/docs/postgresql/Instance-Sharing/
apiVersion: services.cloud.sap.com/v1
kind: ServiceInstance
metadata:
  name: btp-postgres-ref
  namespace: default
spec:
  serviceOfferingName: postgresql-db
  servicePlanName: "reference"
  externalName: btp-postgres-ref
  parameters:
      source_instance_id: "b7f13380-17e7-4541-81df-7a81177aa0e0"
```

https://wiki.one.int.sap/wiki/display/SAPCMMNTY/BTP+PostgreSQL+Database  
https://github.wdf.sap.corp/sap-community/com.sap.community.k8s.kyma/tree/main/btp-postgresql  

https://pages.github.tools.sap/cloudservices/docs/postgresql/Configurations/  
https://help.sap.com/docs/postgresql-hyperscaler-option/postgresql-on-sap-btp-hyperscaler-option-c92112ee69784c3383a0fb8361156a6f/parameters  


```yaml
# parameter configuration options:
# https://help.sap.com/docs/postgresql-hyperscaler-option/postgresql-on-sap-btp-hyperscaler-option-c92112ee69784c3383a0fb8361156a6f/parameters
# for Kyma cluster IPs refer to
# https://github.com/SAP-samples/kyma-runtime-extension-samples/blob/main/get-egress-ips/get-egress-ips.sh
apiVersion: services.cloud.sap.com/v1
kind: ServiceInstance
metadata:
  name: btp-postgres-shared
  namespace: quovadis-btp
spec:
  serviceOfferingName: postgresql-db
  servicePlanName:  standard #development
  externalName: btp-postgres-shared
  parameters:
      engine_version: "15"
      #memory: 4 #2
      #storage: 50 #20
      multi_az: false
      backup_retention_period: 14
      allow_access: "130.214.104.158, 130.214.104.158, 130.214.104.158"
      #WARNING - DO NOT ADD ANY OTHER IPS HERE, ONLY THE IPS OF OUR KYMA CLUSTER MUST BE LISTED!
      instance_shares:
          op: add
          values:
              - "63b9c5f7-0178-4b04-9650-4e50cdba9fd7"      
---
apiVersion: services.cloud.sap.com/v1
kind: ServiceBinding
metadata:
  name: btp-postgres-shared-binding-admin
  namespace: quovadis-btp
spec:
  serviceInstanceName: btp-postgres-shared
  externalName: btp-postgres-shared-binding-admin
  secretName: btp-postgres-shared-binding-admin
---
# Separate YAML for postgres instance sharing
# https://pages.github.tools.sap/cloudservices/docs/postgresql/Instance-Sharing/
apiVersion: services.cloud.sap.com/v1
kind: ServiceInstance
metadata:
  name: btp-postgres-shared
  namespace: quovadis-btp
spec:
  serviceOfferingName: postgresql-db
  servicePlanName:  standard
  externalName: btp-postgres-shared
  parameters:
      instance_shares:
          op: add
          values:
              - "63b9c5f7-0178-4b04-9650-4e50cdba9fd7"
              # BTP subaccount ID of sapit-community-dev-mule subaccount (Tenant ID)

---
# sharing the btp postgres instance from the btp-postgres Kyma namespace
# https://pages.github.tools.sap/cloudservices/docs/postgresql/Instance-Sharing/
apiVersion: services.cloud.sap.com/v1
kind: ServiceInstance
metadata:
  name: btp-postgres-ref-contenthub
spec:
  serviceOfferingName: postgresql-db
  servicePlanName: "reference"
  externalName: btp-postgres-ref-contenthub
  parameters:
      source_instance_id: "4d70c20c-f81a-4a38-a462-252fa5ac6c60"
---
apiVersion: services.cloud.sap.com/v1
kind: ServiceBinding
metadata:
  name: btp-postgres-shared-binding-contenthub
  namespace: contenthub-dev
spec:
  serviceInstanceName: btp-postgres-ref-contenthub
  externalName: btp-postgres-shared-binding-contenthub
  secretName: btp-postgres-shared-binding-contenthub

```

https://wiki.one.int.sap/wiki/display/SAPCMMNTY/BTP+PostgreSQL+Database  

https://github.wdf.sap.corp/sap-community/com.sap.community.k8s.kyma/tree/main/btp-postgresql  

https://github.wdf.sap.corp/sap-community/com.sap.community.k8s.kyma  

https://pages.github.tools.sap/cloudservices/docs/postgresql/Service-Offering/  

https://wiki.one.int.sap/wiki/display/OrcaDev/Hyperscaler+Postgresql+DB+configuration  
