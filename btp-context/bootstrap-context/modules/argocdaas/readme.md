argocdaas
===============



## Troubleshooting


```
time="2***" level=fatal msg="rpc error: code = PermissionDenied desc = permission denied: clusters, create, https://api.***.stage.kyma.ondemand.com, sub: ***, iat: ***"

```

https://github.com/argoproj/argo-cd/discussions/7347  

```
argocd --config argocd_config.json account get-user-info
Logged In: true
Username: ***
Issuer: https://***.accounts400.ondemand.com
Groups: Workzone_Admin,argoCD_Admin

```