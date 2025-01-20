variable "project_id" {
  type = string
  description = "ID do projeto GCP"
}

variable "region" {
  type = string
  description = "Região do projeto GCP (e.g., us-central1)"
  default = "us-central1"
}

variable "cluster_name" {
  type = string
  description = "Nome do cluster GKE para production"
  default = "urbana-chatbot-production-cluster"
}

variable "node_count" {
  type = number
  description = "Número de nós no cluster production"
  default = 3
}

variable "machine_type" {
  type = string
  description = "Tipo de máquina dos nós do cluster production (e.g., e2-standard-4)"
  default = "e2-standard-4"
}

variable "kubernetes_version" {
  type = string
  description = "Versão do Kubernetes para o cluster production"
  default = "1.27.1"
}