resource "google_container_cluster" "cluster" {
  provider = google-beta

  name               = var.cluster_name
  project            = var.project
  location           = var.region
  min_master_version = var.gke_version

  network    = google_compute_network.network.self_link
  subnetwork = google_compute_subnetwork.subnetwork.self_link

  maintenance_policy {
    daily_maintenance_window {
      start_time = "23:00"
    }
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  resource_labels = {
    "proyecto"    = "infra-cloud"
    "environment" = "sandbox"
    "owner"       = "me"
  }

  // Decouple the default node pool lifecycle from the cluster object lifecycle
  // by removing the node pool and specifying a dedicated node pool in a
  // separate resource below.
  remove_default_node_pool = "true"
  initial_node_count       = 1

  // Configure various addons
  addons_config {
    // Enable network policy (Calico)
    network_policy_config {
      disabled = false
    }
  }

  // Disable basic authentication and cert-based authentication.
  // Empty fields for username and password are how to "disable" the
  // credentials from being generated.
  master_auth {
    client_certificate_config {
      issue_client_certificate = "false"
    }
  }

  // Enable network policy configurations (like Calico) - for some reason this
  // has to be in here twice.
  network_policy {
    enabled = "true"
  }

  // Allocate IPs in our subnetwork
  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.subnetwork.secondary_ip_range.0.range_name
    services_secondary_range_name = google_compute_subnetwork.subnetwork.secondary_ip_range.1.range_name
  }

  // Specify the list of CIDRs which can access the master's API
  master_authorized_networks_config {
    cidr_blocks {
      display_name = "bastion"
      cidr_block   = format("%s/32", google_compute_instance.bastion.network_interface.0.network_ip)
    }
  }
  // Configure the cluster to have private nodes and private control plane access only
  private_cluster_config {
    enable_private_endpoint = "true"
    enable_private_nodes    = "true"
    master_ipv4_cidr_block  = "172.16.0.16/28"
  }

  // Allow plenty of time for each operation to finish (default was 10m)
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  depends_on = [
    google_project_service.service,
    google_project_iam_member.service-account,
    google_project_iam_member.service-account-custom,
    google_compute_router_nat.nat,
  ]

}

// A dedicated/separate node pool where workloads will run.  A regional node pool
// will have "node_count" nodes per zone, and will use 3 zones.  This node pool
// will be 3 nodes in size and use a non-default service-account with minimal
// Oauth scope permissions.
resource "google_container_node_pool" "cloud_pool" {
  provider = google-beta

  name       = "cloud-pool"
  location   = var.region
  cluster    = google_container_cluster.cluster.name
  version    = var.gke_version
  node_count = "1"

  // Repair any issues but don't auto upgrade node versions
  management {
    auto_repair  = "true"
    auto_upgrade = "true"
  }

  node_config {
    machine_type = var.gke_machine_type
    disk_type    = var.gke_disk_type
    disk_size_gb = var.gke_disk_size
    image_type   = "COS"
    preemptible  = var.gke_preemptible

    // Use the cluster created service account for this node pool
    service_account = google_service_account.gke-sa.email

    // Use the minimal oauth scopes needed
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
    ]

    labels = {
      cluster       = var.cluster_name
      "proyecto"    = "infra-cloud"
      "environment" = "sandbox"
    }
  }

  depends_on = [
    google_container_cluster.cluster,
  ]
}
