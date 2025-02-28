terraform {
    required_version = "~> 1.9"

    required_providers {
        google = {
            source  = "hashicorp/google"
            version = "~> 6.0"
        }
    
        kubernetes = {
            source  = "hashicorp/kubernetes"
            version = "~> 2.0"
        }

        helm = {
            source = "hashicorp/helm"
            version = "~> 2.0"
        }
    }

    backend "gcs" {
        bucket = "codeflix-terraform"
        prefix  = "states/terraform.crds.tfstate"
    }
}

provider "google" {
    project = var.project_id
    region  = var.region
}

data "google_client_config" "default" {}

data "google_container_cluster" "gke" {
    name     = var.cluster_name
    location = var.region
}

provider "kubernetes" {
    host                   = "https://${data.google_container_cluster.gke.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.gke.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
    kubernetes {
        host                   = "https://${data.google_container_cluster.gke.endpoint}"
        token                  = data.google_client_config.default.access_token
        cluster_ca_certificate = base64decode(data.google_container_cluster.gke.master_auth[0].cluster_ca_certificate)
    }
}