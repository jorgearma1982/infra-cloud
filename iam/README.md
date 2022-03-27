# Infra Cloud Sandbox IAM

Este repo incluye código para constuir y gestionar la infraestructura cloud necesaria para la gestión de cuentas
de servicio con terraform en Google Cloud.

Usamos terraform para automatizar la construcción de los recursos de cuentas de servicio.

## Estructura del proyecto

Este proyecto esta conformado por los siguientes archivos:

- *version.tf:* Definición de versión de terraform y plugin de proveedor.
- *terraform.tfvars:* Definición de variables para proyecto.
- *iam.tf:* Definición de creación de cuentas de servicio.

## Requisitos

Para el desarrollo y pruebas de la infraestructura definida en el código de este proyecto se necesita que el
desarrollador o ingeniero cloud tenga instalado en su máquina local el siguiente software instalado:

 * linux/macos
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

## Generando la configuración

El contenido del archivo `iam.tf` es así:


``` shell
$ cat iam.tf
variable "project_id" {
  description = "project id"
}

provider "google" {
  project = var.project_id
}

resource "google_service_account" "terraform_sa" {
  account_id   = "terraform-sandbox"
  display_name = "Terraform Sandbox Service Account"
}

resource "google_project_iam_member" "terraform_owner_binding" {
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}

```

## Inicializando la configuración

Usamos el comando init para inicializar el proyecto:

``` shell
$ terraform init
```

Note que se instalan los plugins para el proveedor de google cloud.

## Validando la configuración

Antes de poder aplicar esta automatización, debemos asegurarnos que el código es conforme a las mejores práctiacas
y debemos realizar una planeación para validar la correcta configuración.

Usamos el comando validate:

``` shell
$ terraform validate
```

Si no tenemos problemas con sintaxis, realizamos la planeación:

``` shell
$ terraform plan
```

Al final nos imprime la salida de los datos de la VPC.

## Desplegando lo recursos

Después de que se realizaron las validaciones y la planificación se debe aplicar con el comando:

``` shell
$ terraform apply
```

Al final nos imprime la salida de los datos de la cuenta.

## Verificaciones

Ahora debemos verificar que el recurso se ha creado, usaremos gcloud para esto:

``` shell
$ gcloud iam service-accounts list | grep terraform-sandbox
```

## Limpieza

Para limpiar o destruir los recursos que se generaron ejecutar:

``` shell
$ terraform destroy
```
