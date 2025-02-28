variable "email_for_lets_encrypt" {
  description = "Email para notificações do Let's Encrypt"
  type        = string
  default     = "admin@example.com"
}

variable "project_id" {
  description = "ID do projeto no Google Cloud"
  type        = string
}

variable "region" {
  description = "Região do Google Cloud"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Nome do cluster GKE"
  type        = string
  default     = "whatsapp-chatbot-cluster"
} 