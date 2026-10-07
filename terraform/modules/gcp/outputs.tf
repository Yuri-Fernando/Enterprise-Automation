output "bucket_name" {
  description = "Name of the created GCS bucket."
  value       = google_storage_bucket.this.name
}

output "bucket_url" {
  description = "gs:// URL of the created GCS bucket."
  value       = google_storage_bucket.this.url
}

output "network_id" {
  description = "ID of the created VPC network."
  value       = google_compute_network.this.id
}

output "network_self_link" {
  description = "Self-link of the created VPC network."
  value       = google_compute_network.this.self_link
}

output "subnetwork_id" {
  description = "ID of the created subnetwork."
  value       = google_compute_subnetwork.this.id
}
