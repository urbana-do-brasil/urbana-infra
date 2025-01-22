terraform {
  required_version = "~> 1.9"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"
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