variable "project_id" {
  description = "project id"
}

resource "google_service_account" "terraform_sa" {
  project      = var.project_id
  account_id   = "terraform-sandbox"
  display_name = "Terraform Sandbox Service Account"
}

resource "google_project_iam_member" "terraform_owner_binding" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}

