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
}

variable "node_count" {
  type = number
  description = "Número de nós no cluster staging"
}

variable "machine_type" {
  type = string
  description = "Tipo de máquina dos nós do cluster staging (e.g., e2-medium)"
}

variable "kubernetes_version" {
  type = string
  description = "Versão do Kubernetes para o cluster staging"
}