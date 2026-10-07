# ---------------------------------------------------------------------------
# Minimal GCP footprint: one GCS bucket + one custom-mode VPC/subnet.
# Never instantiated by terraform/providers.tf or terraform/environments/ —
# see README.md in this directory for why (no GCP project/credentials in
# this portfolio lab; validate-only, never plan/apply against a real
# project).
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

locals {
  # GCP label keys/values must be lowercase alphanumeric + [-_], <=63 chars
  # — unlike AWS tags, which are case-sensitive free text. Callers must
  # already pass lowercase keys in var.labels; this module does not
  # re-case them (silently mutating caller-supplied labels would hide the
  # mismatch this convention depends on — see README.md).
  common_labels = merge(var.labels, { name = var.name_prefix })
}

resource "google_storage_bucket" "this" {
  name                        = "${var.name_prefix}-artifacts"
  project                     = var.project_id
  location                    = var.region
  storage_class               = var.bucket_storage_class
  force_destroy               = var.bucket_force_destroy
  uniform_bucket_level_access = true

  versioning {
    enabled = var.bucket_versioning_enabled
  }

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }

  labels = local.common_labels
}

resource "google_compute_network" "this" {
  name                    = "${var.name_prefix}-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "this" {
  name          = "${var.name_prefix}-subnet"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.this.id
  ip_cidr_range = var.subnet_cidr

  private_ip_google_access = true

  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
}
