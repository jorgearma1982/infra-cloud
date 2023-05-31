terraform {
  backend "gcs" {
    bucket = "infra-cloud-sandbox-tfstate"
    prefix = "iam/sandbox"
  }
}
