// Create the GKE service account
resource "google_service_account" "gke-sa" {
  account_id   = format("%s-node-sa", var.cluster_name)
  display_name = "GKE Security Service Account"
  project      = var.project
}

// Add the service account to the project
resource "google_project_iam_member" "service-account" {
  count   = length(var.service_account_iam_roles)
  project = var.project
  role    = element(var.service_account_iam_roles, count.index)
  member  = format("serviceAccount:%s", google_service_account.gke-sa.email)
}

// Add user-specified roles
resource "google_project_iam_member" "service-account-custom" {
  count   = length(var.service_account_custom_iam_roles)
  project = var.project
  role    = element(var.service_account_custom_iam_roles, count.index)
  member  = format("serviceAccount:%s", google_service_account.gke-sa.email)
}

// Enable required services on the project
resource "google_project_service" "service" {
  count   = length(var.project_services)
  project = var.project
  service = element(var.project_services, count.index)

  // Do not disable the service on destroy. On destroy, we are going to
  // destroy the project, but we need the APIs available to destroy the
  // underlying resources.
  disable_on_destroy = false
}

// Create a network for GKE
resource "google_compute_network" "network" {
  name                    = "${var.project}-${var.project_env}-cluster-vpc"
  project                 = var.project
  auto_create_subnetworks = false

  depends_on = [
    google_project_service.service,
  ]
}

// Create subnets
resource "google_compute_subnetwork" "subnetwork" {
  name          = "${var.project}-${var.project_env}-cluster-net"
  project       = var.project
  network       = google_compute_network.network.self_link
  region        = var.region
  ip_cidr_range = var.vpc_cidr_range

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = format("%s-pod-range", var.cluster_name)
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = format("%s-svc-range", var.cluster_name)
    ip_cidr_range = var.services_cidr
  }
}
// Create an external NAT IP
resource "google_compute_address" "nat" {
  name    = format("%s-nat-ip", var.cluster_name)
  project = var.project
  region  = var.region

  depends_on = [
    google_project_service.service,
  ]
}

// Create a cloud router for use by the Cloud NAT
resource "google_compute_router" "router" {
  name    = format("%s-cloud-router", var.cluster_name)
  project = var.project
  region  = var.region
  network = google_compute_network.network.self_link

  bgp {
    asn = 64514
  }
}

// Create a NAT router so the nodes can reach DockerHub, etc
resource "google_compute_router_nat" "nat" {
  name    = format("%s-cloud-nat", var.cluster_name)
  project = var.project
  router  = google_compute_router.router.name
  region  = var.region

  nat_ip_allocate_option = "MANUAL_ONLY"

  nat_ips = [google_compute_address.nat.self_link]

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.subnetwork.self_link
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE", "LIST_OF_SECONDARY_IP_RANGES"]

    secondary_ip_range_names = [
      google_compute_subnetwork.subnetwork.secondary_ip_range.0.range_name,
      google_compute_subnetwork.subnetwork.secondary_ip_range.1.range_name,
    ]
  }
}

// Bastion Host
locals {
  hostname = "${var.project}-bastion-${var.project_env}"
}

// Dedicated service account for the Bastion instance
resource "google_service_account" "bastion" {
  account_id   = format("%s-bastion-sa", var.cluster_name)
  display_name = "GKE Bastion SA"
}

// Allow access to the Bastion Host via SSH
resource "google_compute_firewall" "bastion-ssh" {
  name          = "allow-ssh-cloud-bastion-${var.project_env}"
  network       = google_compute_network.network.name
  direction     = "INGRESS"
  project       = var.project
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["bastion"]
}

// The user-data script on Bastion instance provisioning
data "template_file" "startup_script" {
  template = <<-EOF
  sudo apt-get update -y
  sudo apt-get install -y tinyproxy
  EOF

}

resource "google_compute_address" "bastion_nat_ip" {
  name = "${var.project}-bastion-nat-ip-${var.project_env}"
}

// The Bastion Host
resource "google_compute_instance" "bastion" {
  name         = local.hostname
  machine_type = "g1-small"
  zone         = var.zone
  project      = var.project
  tags         = ["bastion"]
  labels = {
    "proyecto"      = "infra-cloud"
    "environment"   = "${var.project_env}"
  }

  // Specify the Operating System Family and version.
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-focal-v20211118"
      type  = "pd-standard"
      size  = "20"
    }
  }

  // Ensure that when the bastion host is booted, it will have tinyproxy
  metadata_startup_script = data.template_file.startup_script.rendered

  // Define a network interface in the correct subnet.
  network_interface {
    subnetwork = google_compute_subnetwork.subnetwork.name

    // Add an static external IP.
    access_config {
      network_tier = "PREMIUM"
      nat_ip       = google_compute_address.bastion_nat_ip.address
    }
  }

  // Allow the instance to be stopped by terraform when updating configuration
  allow_stopping_for_update = true

  service_account {
    email  = google_service_account.bastion.email
    scopes = ["cloud-platform"]
  }

  // local-exec providers may run before the host has fully initialized. However, they
  // are run sequentially in the order they were defined.
  //
  // This provider is used to block the subsequent providers until the instance
  // is available.
  provisioner "local-exec" {
    command = <<EOF
        READY=""
        for i in $(seq 1 20); do
          if gcloud compute ssh ${local.hostname} --project ${var.project} --zone ${var.zone} --command uptime; then
            READY="yes"
            break;
          fi
          echo "Waiting for ${local.hostname} to initialize..."
          sleep 10;
        done
        if [[ -z $READY ]]; then
          echo "${local.hostname} failed to start in time."
          echo "Please verify that the instance starts and then re-run `terraform apply`"
          exit 1
        fi
EOF
  }
}

