resource "google_storage_bucket" "backup_bucket" {
  name     = "${var.project_id}-k8s-backup"
  location = var.region
  force_destroy = false
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_service_account" "velero" {
  account_id   = "velero-sa"
  display_name = "Velero Service Account"
}

resource "google_storage_bucket_iam_member" "velero_bucket_admin" {
  bucket = google_storage_bucket.backup_bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.velero.email}"
}

resource "google_service_account_key" "velero_key" {
  service_account_id = google_service_account.velero.name
}

resource "kubernetes_secret" "velero_credentials" {
  metadata {
    name      = "velero-credentials"
    namespace = "velero"
  }

  data = {
    "cloud-credentials" = base64decode(google_service_account_key.velero_key.private_key)
  }

  depends_on = [helm_release.velero]
}

resource "helm_release" "velero" {
  name       = "velero"
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  version    = "4.0.3"
  namespace  = "velero"
  create_namespace = true

  set {
    name  = "initContainers[0].name"
    value = "velero-plugin-for-gcp"
  }

  set {
    name  = "initContainers[0].image"
    value = "velero/velero-plugin-for-gcp:v1.6.0"
  }

  set {
    name  = "initContainers[0].volumeMounts[0].mountPath"
    value = "/target"
  }

  set {
    name  = "initContainers[0].volumeMounts[0].name"
    value = "plugins"
  }

  set {
    name  = "configuration.provider"
    value = "gcp"
  }

  set {
    name  = "configuration.backupStorageLocation.name"
    value = "gcp"
  }

  set {
    name  = "configuration.backupStorageLocation.bucket"
    value = google_storage_bucket.backup_bucket.name
  }

  set {
    name  = "configuration.backupStorageLocation.config.region"
    value = var.region
  }

  set {
    name  = "credentials.secretContents.cloud"
    value = ""
  }

  set {
    name  = "schedules.daily-backup.schedule"
    value = "0 1 * * *"
  }

  set {
    name  = "schedules.daily-backup.template.ttl"
    value = "240h"
  }
} 