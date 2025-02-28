variable "gemini_api_key" {
  description = "API Key para o serviço Gemini"
  type        = string
  sensitive   = true
}

variable "whatsapp_token" {
  description = "Token de verificação para o webhook do WhatsApp Business"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Nome de domínio para a aplicação"
  type        = string
  default     = "api.example.com"
}

variable "grafana_admin_password" {
  description = "Senha para o usuário admin do Grafana"
  type        = string
  sensitive   = true
  default     = "admin"
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