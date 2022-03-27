# RBAC y KUBECONFIG para gha-deployer

## Creamos el namespace

Creamos el namespace para la cuenta de servicio aplicando el manifiesto `0_namespace.yml`:

```
$ kubectl apply -f 0_namespace.yml
```

## Crear cuenta de servicio

Creamos la cuenta de servicio aplicando el manifiesto `10_serviceaccount.yml`:

Aplicamos el manifiesto
```
$ kubectl apply -f 10_serviceaccount.yml
```

## Crear Cluster Role

Creamos la el rol de cluster aplicando el manifiesto `11_clusterrole.yml`:

```
$ kubectl apply -f 11_clusterrole.yml
```
## Crear Cluster Role Binding

Creamos la el binding del rol de cluster aplicando el manifiesto `12_clusterrolebinding.yml`:

```
$ kubectl apply -f 12_clusterrolebinding.yml
```

## Creamos KUBECONFIG

Ejecutamos el script `kubernetes_add_service_account_kubeconfig.sh` usando como parametros el nombre
de la cuenta de servicio y el namespace.

```
$ kubernetes_add_service_account_kubeconfig.sh gha-deployer-sandbox sandbox
```

El script dara como resultado un archivo en `/tmp/kube`, algo así:

```
$ ls -l /tmp/kube
total 8
-rw-r--r-- 1 sysadmin 1119 Feb 25 11:01 ca.crt
-rw------- 1 sysadmin 2912 Feb 25 11:01 k8s-gha-deployer-sandbox-sandbox-conf
```

Como se puede ver ahi se almaceno el archivo del certificado asociado al secret de la cuenta de servicio. El archivo
`k8s-gha-deployer-sandbox-sandbox-conf` tiene la configuración en formato `KUBECONFIG`.

## Subir kubeconfig a github secrets

Para subir este `KUBECONFIG` a un secreto en github secrets y que pueda ser usado por un workflow, debemos convertir
el archivo a `BASE64`, por ejemplo:

```
$ base64 k8s-gha-deployer-sandbox-sandbox-conf
```

La salida del comando debe ser copiada (sin saltos de línea) dentro del valor del secret.

## Referencias

En las siguientes ligas podemos encontrar información adicional para el manejo de RBAC en Kubernetes:

* [Kubernetes - Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
* [Kubernetes - Configure Service Accounts for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
* [Kubernetes - Managing Service Accounts](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/)
