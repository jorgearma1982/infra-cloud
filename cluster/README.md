# Infra Cloud Sandbox Kubernetes Cluster

Este repo incluye código para construir y gestionar la infraestructura cloud necesaria para correr clusters de
contenedores con kubernetes en Google Cloud.

Usamos terraform para automatizar la construcción de los recursos de red y del cluster.

## Estructura del proyecto

Este proyecto esta conformado por los siguientes archivos:

* provider.tf: Definición de proveedor cloud
* backend.tf: Definición de backend para estado de proyecto
* versions.tf: Definición de versiones de plugins del proyecto
* variables.tf: Definición de variables del proyecto
* network.tf: Definición de creación de vpc, subredes y bastion
* main.tf: Definición de cluster kubernetes
* terraform.tfvars: Definición de parámetros de proyecto
* outputs.tf: Salida de datos generados durante la construcción

## Recursos Cloud

Los recursos cloud que gestionamos con este proyecto son:

**vpc.tf:**

* google_service_account: Crea cuentas de servicio para instancias de computo y el cluster.
* google_project_iam_member: Agrega cuenta de servicio como miembro de función IAM.
* google_project_service: Crea servicios.
* google_compute_network: Crea una red de VPC.
* google_compute_subnetwork: Crea subredes en una red de VPC.
* google_compute_address: Crea direcciones IP externas.
* google_compute_router: Crea router cloud.
* google_compute_router_nat: Crea NAT.
* google_compute_firewall: Crea reglas de firewall.
* google_compute_instance: Crea instancias de computo.

**main.tf:**

* google_container_cluster: Crea cluster kubernetes.
* google_container_node_pool: Crea pool de nodos en cluster kubernetes.

## Requisitos

Para el desarrollo y pruebas de la infraestructura definida en el código de este proyecto se necesita que el
desarrollador o ingeniero cloud tenga instalado en su máquina local el siguiente software instalado:

 * linux/macos
 * terraform 1.3.7
 * gcloud 425.0.x
 * kubectl 1.24.x

Para construir la infraestructura en GCP se requiere lo siguiente:

 * Proyecto en google cloud
 * Cuenta de administrador google cloud
 * Privilegios de dueño del proyecto google cloud
 * Cuenta de servicio IAM en proyecto google cloud
 * Llave JSON asociada a cuenta de servicio
 * Deposito de almacenamiento google cloud
 * Privilegios para leer y escribir en el bucket

**IMPORTANTE:** Todos los recursos deben etiquetarse de acuerdo al proyecto asociado.

En Github Actions, en el proyecto se debe definir los siguientes secretos:

* GCP_PROJECT_ID: Identificador de Proyecto de Google Cloud
* GCP_SA_KEY: Contenido de llave json de cuenta de servicio de Google Cloud
 
## Generando la configuración

Terraform almacena el estado de la infraestructura en una API interna definida en un archivo JSON, este puede estar
en el local en el equipo del desarrollador en la etapa inicial, sin embargo, para mantener la infraestructura en
un estado consistente almacenaremos el estado de terraform en un deposito de almacenamiento de google cloud, así
podrá ser usado desde nuestra herramienta de Integración Continua.

Editamos el archivo `terraform.tf` para definir el nombre del deposito donde almacenaremos el estado de terraform.

```shell
$ vim terraform.tf
```

En nuestro ejemplo usamos estos datos:

``` yaml
terraform {
  backend "gcs" {
    bucket = "infra-cloud-sandbox-tfstate"
    prefix = "cluster/sandbox"
  }
}
```

Editamos el archivo `terraform.tfvars` para definir el nombre del proyecto de google cloud en donde construiremos
la infra, el nombre del ambiente del proyecto, y también la región y la zona.

```shell
$ vim terraform.tfvars
```

En nuestro ejemplo usamos estos datos:

```shell
project          = "infra-cloud"
project_env      = "sandbox"
region           = "us-central1"
zone             = "us-central1-f"
gke_version      = "1.24.11-gke.1000"
cluster_name     = "cloud-sandbox"
vpc_cidr_range   = "10.130.0.0/20"
services_cidr    = "10.228.0.0/20"
pods_cidr        = "10.224.0.0/14"
gke_machine_type = "e2-small"
gke_disk_size    = "10"
gke_disk_type    = "pd-standard"
gke_preemptible  = "true"
```

El nombre del proyecto lo puedes obtener con el comando:

```shell
$ gcloud config get-value project
Your active configuration is: [infra-cloud]
infra-cloud
```

Por default usamos la región `us-central1` y la zona `us-central1-f`.

## Inicializando la configuración

Usamos el comando init para inicializar el proyecto:

```shell
$ terraform init
```

Note que se instalan los plugins para el proveedor de google cloud.

## Validando la configuración

Antes de poder aplicar esta automatización, debemos asegurarnos que el código es conforme a las mejores prácticas
y debemos realizar una planeación para validar la correcta configuración.

Usamos el comando validate:

```shell
$ terraform validate
```

Si no tenemos problemas con sintaxis, realizamos la planeación:

```shell
$ terraform plan
```

Al final nos imprime la salida de los datos del cluster.

## Desplegando lo recursos

Después de que se realizaron las validaciones y la planificación se debe aplicar con el comando:

```shell
$ terraform apply
```

Al final nos imprime la salida de los datos del cluster.

## Verificaciones

Ahora debemos verificar que el recurso se ha creado, usaremos gcloud para esto:

```shell
$ gcloud container clusters list
```

Ya que este es un cluster de tipo privado, solo podremos conectarnos al cluster
a través de la máquina bastión:

```shell
$ gcloud compute ssh infra-cloud-bastion-sandbox -- -L8888:127.0.0.1:8888
```

**IMPORTANTE:** Esta ventana se mantiene abierta para mantener el túnel abierto.

Ahora nos podemos traer las credenciales del proyecto para kubectl:

```shell
$ gcloud container clusters get-credentials --internal-ip cloud-sandbox --region us-central1
```

Exportamos la variable de ambiente del PROXY:

```shell
$ export HTTPS_PROXY=localhost:8888
```

Listamos las configuraciones de los clusters en kubectl:

```shell
$ kubectl config get-contexts
```

Solicitamos la información general del cluster:

```shell
$ kubectl cluster-info
```

Mostramos la información de los nodos:

```shell
$ kubectl get nodes
```

Mostramos la información de los pods:

```shell
$ kubectl get pods --all-namespaces
```

## Limpieza

Para limpiar o destruir los recursos que se generaron ejecutar:

```shell
$ terraform destroy
```

## Estilo de código

Usamos `EditorConfig` para ayudar a mantener la consistencia de los estilos de código entre múltiples desarrolladores
que trabajan en este proyecto usando diferentes editores ó IDEs. El archivo `.editorconfig` define las reglas de
edición del código en este proyecto, se aconseja integrarlo en tu editor o IDE preferido.

Hemos usado el framework `pre-commit` para automatizar las tareas pre commit de git. En el archivo
`.pre-commit-config.yaml` se definen los hooks a usar en el proyecto.

Usamos `tflint` para lintear el código, su configuración se almacena en el archivo `.tflint.hcl`.

También usamos `markdown-link-check` para validar los urls en los archivos markdown.

## Referencias

La siguiente es una lista de documentación de referencia que se puede usar para entender el código usado:

* [google_service_account](https://registry.terraform.io/providers/hashicorp/google/4.0.0/docs/resources/google_service_account)
* [google_project_iam_member](https://registry.terraform.io/providers/hashicorp/google/4.0.0/docs/resources/google_project_iam#google_project_iam_member)
* [google_project_service](https://registry.terraform.io/providers/hashicorp/google/4.0.0/docs/resources/google_project_service)
* [google_compute_network](https://registry.terraform.io/providers/hashicorp/google/4.0.0/docs/data-sources/compute_network)
* [google_compute_subnetwork](https://registry.terraform.io/providers/hashicorp/google/4.0.0/docs/resources/compute_subnetwork)
* [google_compute_address](https://registry.terraform.io/providers/hashicorp/google/4.0.0/docs/resources/compute_address)
* [google_compute_router](https://registry.terraform.io/providers/hashicorp/google/4.0.0/docs/resources/compute_router)
* [google_compute_router_nat](https://registry.terraform.io/providers/hashicorp/google/4.0.0/docs/resources/compute_router_nat)
* [google_compute_firewall](https://registry.terraform.io/providers/hashicorp/google/4.0.0/docs/resources/compute_firewall)
* [google_compute_instance](https://registry.terraform.io/providers/hashicorp/google/4.0.0/docs/resources/compute_instance)
* [google_container_cluster](https://registry.terraform.io/providers/hashicorp/google/4.0.0/docs/resources/container_cluster)
* [google_container_node_pool](https://registry.terraform.io/providers/hashicorp/google/4.0.0/docs/resources/container_node_pool)
* [editorconfig](https://editorconfig.org/)
* [editorconfig-vim](https://github.com/editorconfig/editorconfig-vim)
* [pre-commit](https://pre-commit.com/)
* [markdown-link-check](https://github.com/tcort/markdown-link-check)
