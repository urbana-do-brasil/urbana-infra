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
