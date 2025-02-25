resource "kubernetes_namespace" "whatsapp_chatbot" {
    metadata {
        name = "whatsapp_chatbot"
    }
}

resource "kubernetes_secret" "secret_gemini" {
    metadata {
        name      = "gemini-secret"
        namespace = kubernetes_namespace.whatsapp_chatbot.metadata.0.name
    }
    data = {
        api_key = var.gemini_api_key
    }
}

resource "kubernetes_secret" "secret_whatsapp" {
    metadata {
        name      = "whatsapp-secret"
        namespace = kubernetes_namespace.whatsapp_chatbot.metadata.0.name
    }
    data = {
        token = var.whatsapp_token
    }
}

resource "kubernetes_manifest" "api_gateway_deploy" {
    manifest = yamldecode(file("../../k8s/api-gateway-deployment.yaml"))
    depends_on = [kubernetes_secret.secret_gemini, kubernetes_secret.secret_whatsapp]
}

resource "kubernetes_manifest" "api_gateway_service" {
    manifest = yamldecode(file("../../k8s/api-gateway-service.yaml"))
    depends_on = [kubernetes_manifest.api_gateway_deploy]
}

resource "kubernetes_ingress_v1" "api_gateway_ingress" {
    metadata {
        name      = "api-gateway-ingress"
        namespace = "whatsapp_chatbot"
        annotations = {
            "kubernetes.io/ingress.class" = "gce"
            "networking.gke.io/managed-certificates" = "api-gateway-certificate"
        }
    }

    spec {
        rule {
            http {
                path {
                    path = "/"
                    path_type = "Prefix"

                    backend {
                        service {
                            name = kubernetes_manifest.api_gateway_service.metadata[0].name
                            port {
                                number = 80
                            }
                        }
                    }
                }
            }
        }
    }

    lifecycle {
        ignore_changes = [metadata[0].annotations["ingress.kubernetes.io/backends"]]
    }

    depends_on = [kubernetes_manifest.api_gateway_service]
}

resource "google_compute_managed_ssl_certificate" "api_gateway_certificate" {
    name = "api-gateway-certificate"

    managed {
        domains = [kubernetes_ingress_v1.api_gateway_ingress.status.0.load_balancer.0.ingress.0.ip]
    }

    lifecycle {
        create_before_destroy = true
    }

    depends_on = [kubernetes_ingress_v1.api_gateway_ingress]
}