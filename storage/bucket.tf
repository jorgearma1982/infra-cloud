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
