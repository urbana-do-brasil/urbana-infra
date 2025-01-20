variable "project_id" {
  type = string
  description = "ID do projeto GCP"
}

variable "region" {
  type = string
  description = "Região do projeto GCP (e.g., us-central1)"
  default = "us-central1"
}

variable "replicas_api_gateway" {
  type    = number
  default = 2
}

variable "cluster_name" {
  type = string
  description = "Nome do cluster GKE para staging"
  default = "urbana-chatbot-staging-cluster"
}

variable "node_count" {
  type = number
  description = "Número de nós no cluster staging"
  default = 1
}

variable "machine_type" {
  type = string
  description = "Tipo de máquina dos nós do cluster staging (e.g., e2-medium)"
  default = "e2-medium"
}

variable "kubernetes_version" {
  type = string
  description = "Versão do Kubernetes para o cluster staging"
  default = "1.27.1"
}