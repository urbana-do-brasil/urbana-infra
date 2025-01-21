terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  backend "gcs" {
    bucket = "urbana-chatbot-terraform-state"
    prefix = "terraform/state/staging"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.region
  initial_node_count = var.node_count

  node_config {
    machine_type = var.machine_type
  }
}

resource "google_artifact_registry_repository" "api_gateway" {
  location = var.region
  repository_id = "api-gateway"
  format = "DOCKER"
}