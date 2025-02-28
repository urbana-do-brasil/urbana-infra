variable "project_id" {
  type = string
  description = "ID do projeto GCP"
  default = "extreme-mix-447320-i4"
}

variable "region" {
  type = string
  description = "Região do projeto GCP (e.g., us-central1)"
  default = "us-central1"
}

variable "cluster_name" {
  type = string
  description = "Nome do cluster GKE para staging"
  default = "urbana-chatbot-staging-cluster"
}