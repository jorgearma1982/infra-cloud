// Used to identify the cluster in validate.sh.
output "cluster_name" {
  description = "Convenience output to obtain the GKE Cluster name"
  value       = google_container_cluster.cluster.name
}

output "cluster_endpoint" {
  description = "Cluster endpoint"
  value       = google_container_cluster.cluster.endpoint
}

output "cluster_ca_certificate" {
  sensitive   = true
  description = "Cluster ca certificate (base64 encoded)"
  value       = google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
}

output "get_credentials" {
  description = "Gcloud get-credentials command"
  value       = format("gcloud container clusters get-credentials --project %s --region %s --internal-ip %s", var.project, var.region, var.cluster_name)
}
output "bastion_ssh" {
  description = "Gcloud compute ssh to the bastion host command"
  value       = format("gcloud compute ssh %s --project %s --zone %s -- -L8888:127.0.0.1:8888", google_compute_instance.bastion.name, var.project, google_compute_instance.bastion.zone)
}

output "bastion_kubectl" {
  description = "kubectl command using the local proxy once the bastion_ssh command is running"
  value       = "HTTPS_PROXY=localhost:8888 kubectl get pods --all-namespaces"
}

output "bastion_nat_ip" {
  value       = google_compute_address.bastion_nat_ip.address
  description = "The External IP address of the bastion instance."
}
