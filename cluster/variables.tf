// Required values to be set in terraform.tfvars
variable "project" {
  description = "The project in which to hold the components"
  type        = string
}

// Required values to be set in terraform.tfvars
variable "project_env" {
  description = "The project environment in which to hold the components"
  type        = string
}

variable "region" {
  description = "The region in which to create the VPC network"
  type        = string
}

variable "zone" {
  description = "The zone in which to create the Kubernetes cluster. Must match the region"
  type        = string
}

variable "vpc_cidr_range" {
  description = "vpc_cidr_range"
}

variable "services_cidr" {
  description = "services_cidr"
}

variable "pods_cidr" {
  description = "pods_cidr"
}

variable "gke_version" {
  description = "gke_version"
}

// Optional values that can be overridden or appended to if desired.
variable "cluster_name" {
  description = "The name to give the new Kubernetes cluster."
  type        = string
  default     = "private-cluster"
}

variable "gke_machine_type" {
  description = "gke_machine_type"
}

variable "gke_disk_size" {
  description = "gke_disk_size"
}

variable "gke_disk_type" {
  description = "gke_disk_type"
}

variable "gke_preemptible" {
  description = "gke_preemptible"
}

variable "bastion_tags" {
  description = "A list of tags applied to your bastion instance."
  type        = list(string)
  default     = ["bastion"]
}

variable "k8s_namespace" {
  description = "The namespace to use for the deployment and workload identity binding"
  type        = string
  default     = "default"
}

variable "service_account_iam_roles" {
  type = list(string)

  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
  ]
  description = <<-EOF
  List of the default IAM roles to attach to the service account on the
  GKE Nodes.
  EOF
}

variable "service_account_custom_iam_roles" {
  type    = list(string)
  default = []

  description = <<-EOF
  List of arbitrary additional IAM roles to attach to the service account on
  the GKE nodes.
  EOF
}

variable "project_services" {
  type = list(string)

  default = [
    "cloudresourcemanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "container.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "sqladmin.googleapis.com",
    "securetoken.googleapis.com",
  ]
  description = <<-EOF
  The GCP APIs that should be enabled in this project.
  EOF
}

