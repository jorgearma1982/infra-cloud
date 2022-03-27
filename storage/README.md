# Infra Cloud Sandbox Cloud Storage

Este repo incluye código para constuir y gestionar la infraestructura cloud necesaria para el almacenamiento del
estado de terraform en Google Cloud.

Usamos terraform para automatizar la construcción de los recursos de almacenamiento.

## Estructura del proyecto

Este proyecto esta conformado por los siguientes archivos:

* *version.tf:* Definición de versión de terraform y plugin de proveedor.
* *terraform.tfvars:* Definición de variables para proyecto.
* *bucket.tf:* Definición de creación de bucket.

## Recursos Cloud

Los recursos cloud que gestionamos con este proyecto son:

**bucket.tf:**

* google_storage_bucket: Crear una deposito de almacenamiento en GCP.

## Requisitos

Para el desarrollo y pruebas de la infraestructura definida en el código de este proyecto se necesita que el
desarrollador o ingeniero cloud tenga instalado en su máquina local el siguiente software instalado:

* linux/macos
* python 3.8.x
* python pre-commit
* npm 8.1.x
* npm markdown-link-check
* tflint
* terraform-docs
* terraform 1.0.10
* gcloud 361.0.x

Para constuir la infraestructura en GCP se requiere lo siguiente:

* Proyecto en google cloud
* Cuenta de administrador google cloud
* Privilegios de dueño del proyecto google cloud
* Cuenta de servicio IAM en proyecto google cloud
* Llave JSON asociada a cuenta de servicio
* Deposito de almacenamiento google cloud
* Privilegios para leer y escribir en el bucket

**IMPORTANTE:** Todos los recursos deben etiquetarse de acuerdo al proyecto asociado.

En Github Actions, en el proyecto se debe definir los siguientes secretos:

* SANDBOX_GCP_PROJECT_ID: Identificador de Proyecto de Google Cloud
* SANDBOX_GCP_SA_KEY: Contenido de llave json de cuenta de servicio de Google Cloud
 
## Generando la configuración

El contenido del archivo `bucket.tf` es así:


```
$ cat bucket.tf
variable "project_id" {
  description = "project id"
}

provider "google" {
  project = var.project_id
}

resource "google_storage_bucket" "infra-cloud-sandbox-tfstate" {
  name                        = "infra-cloud-sandbox-tfstate"
  location                    = "US"
  storage_class               = "STANDARD"
  force_destroy               = "false"
  uniform_bucket_level_access = "true"
  labels = {
    "proyecto"      = "infra-cloud"
    "environment"   = "sandbox"
  }
}
```

## Inicializando la configuración

Usamos el comando init para inicializar el proyecto:

```
$ terraform init
```

Note que se instalan los plugins para el proveedor de google cloud.

## Validando la configuración

Antes de poder aplicar esta automatización, debemos asegurarnos que el código es conforme a las
mejores práctiacas y debemos realizar una planeación para validar la correcta configuración.

Usamos el comando validate:

```
$ terraform validate
```

Si no tenemos problemas con sintaxis, realizamos la planeación:

```
$ terraform plan
```

Al final nos imprime la salida de los datos de la VPC.

## Desplegando lo recursos

Después de que se realizaron las validaciones y la planificación se debe aplicar con el comando:

```
$ terraform apply
```

Al final nos imprime la salida de los datos del bucket.

## Verificaciones

Ahora debemos verificar que el recurso se ha creado, usaremos gsutil para esto:

```
$ gsutil ls | grep "infra-cloud-sandbox-tfstate"
```

## Limpieza

Para limpiar o destruir los recursos que se generaron ejecutar:

```
$ terraform destroy
```

## Estilo de código

Usamos `EditorConfig` para ayudar a mantener la consistencia de los estilos de código entre múltiples desarrolladores
que trabajan en este proyecto usando diferentes editores ó IDEs. El archivo `.editorconfig` define las reglas de
edición del código en este proyecto, se aconseja integrarlo en tu editor o IDE preferido.

Hemos usado el framework `pre-commit` para automatizar las tareas pre commit de git. En el archivo
`.pre-commit-config.yaml` se definen los hooks a usar en el proyecto.

Usamos `tflint` para lintear el código, su configuración se almacena en el archivo `.tflint.hcl`.

Tambien usamos `markdown-link-check` para validar los urls en los archivos markdown.

## Referencias

La siguiente es una lista de documentación de referencia que se puede usar para entender el código usado:

* [google_storage_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket)
* [editorconfig](https://editorconfig.org/)
* [editorconfig-vim](https://github.com/editorconfig/editorconfig-vim)
* [pre-commit](https://pre-commit.com/)
* [markdown-link-check](https://github.com/tcort/markdown-link-check)
