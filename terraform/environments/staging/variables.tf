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