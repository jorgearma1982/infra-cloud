# Infra Cloud Sandbox

## Introducción

En este repositorio almacenamos el código de la infraestructura Cloud.

El proposito es tener todos los artefactos necesarios desplegar la infraestructura de los diferentes proyectos
en un solo lugar y hacer uso de herramientas como Google Cloud, terraform y ansible para automatizar los
despliegues de estos recursos.

Los proyectos que vamos a hospedar aqui son:

* Servidor X

Para toda la infraestructura se mantiene un bucket de almacenamiento en común, en donde se almacena el estado
de los recursos de terraform.

* El directorio `storage` incluye código para crear buckets de almacenamiento.

Usamos cuenta de servicio IAM para las cuentas de terraform.

* El directorio `iam` incluye código para crear cuantas de servicio IAM.

Usamos diferentes recursos cloud para aprovisionar la infra de cada proyecto, para los servidores de Telefonía usamos:

* El directorio `cluster` incluye código para crear instancias de computo.
 
## Requisitos

Para esta iniciativa de Infra Cloud se requiere un proyecto nuevo e independiente en Google Cloud, en este caso se creo
el proyecto `infra-cloud` y se configuro la cuenta de facturación.

Para inicializar el proyecto, es necesario que el usuario con privilegios de administrador ejecute los siguientes
comandos:

``` shell
$ gcloud init
```

Después nos autenticamos con google con la cuenta local:

``` shell
$ gcloud auth application-default login
```

Se deben tener habilitar las APIs de los diferentes servicios:

``` shell
$ gcloud services enable cloudresourcemanager.googleapis.com
$ gcloud services enable servicenetworking.googleapis.com
$ gcloud services enable compute.googleapis.com
$ gcloud services enable storage-api.googleapis.com
$ gcloud services enable dns.googleapis.com
$ gcloud services enable iam.googleapis.com
$ gcloud services enable sqladmin.googleapis.com
$ gcloud services enable logging.googleapis.com
$ gcloud services enable monitoring.googleapis.com
$ gcloud services enable securetoken.googleapis.com
$ gcloud services enable container.googleapis.com
```

Una vez que se ha realizado la configuración inicial del proyecto en un equipo local, se debe crear la infraestructura
en el siguiente orden:

* `storage:` Se debe crear primero el bucket para estado de terraform.
* `iam:` Se debe crear en segundo lugar la cuenta de servicio para terraform.
* `cluster:` Se debe crear en cuarto lugar el cluster kubernetes para infra-cloud.

Cuando haya creado la cuenta de servicio para terraform, deberemos generar una llave que será usada por la herramienta
de CI/CD para automatizar los despliegues, ésta se genera así:

``` shell
$ PROJECT_ID=infra-cloud
$ gcloud iam service-accounts keys create key.json \
  --iam-account terraform-sandbox@${PROJECT_ID}.iam.gserviceaccount.com
```

**NOTA:** La llave se almacena en el archivo `key.json`, se sube en un registro en Keeper. Esta se usara después
en la herramienta de CI/CD para automatizar los despliegues.

Con esto ya se puede trabaja con terraform en ese proyecto.

## Storage

En esta sección tenemos el código para automatizar el despliegue de buckets de almacenamiento.

En el archivo `storage/README.md` se incluyen las instrucciones para desplegar el bucket usando terraform.

## IAM

En esta sección tenemos el código para automatizar el despliegue de las cuentas de servicios IAM.

En el archivo `iam/README.md` se incluyen las instrucciones para desplegar las sa usando terraform.

## Cluster

En esta sección tenemos el código para automatizar el despliegue del los clusters de kubernetes.

En el archivo `cluster/README.md` se incluyen las instrucciones para desplegar los clusters de kubernetes usando
terraform.

## Workflow

Usamos los Workflows de Github Actions para automatizar las tareas para construir la infraestructura usando
terraform.

En el directorio `.github/workflows` se encuentran los archivos `.yml` para cada directorio, es decir, el archivo
`storage.yml` es usado para automatizar las tareas dentro del directorio `storage`.

## Recomendaciones

Siempre recuerda hacer la validación previsa y revisión de formato en los archivos de terraform. Se recomienda
usar los git hooks como `pre-commit` para validar los archivos terraform y aplicarles el format.

