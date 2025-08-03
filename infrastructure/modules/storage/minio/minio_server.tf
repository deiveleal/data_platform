resource "kubernetes_deployment" "minio_deploy" {
  metadata {
    name      = "minio-deploy"
    namespace = kubernetes_namespace.minio_ns.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        App = "Minio"
      }
    }

    template {
      metadata {
        labels = {
          App = "Minio"
        }
      }

      spec {
        container {
          image = "minio/minio:latest"
          name  = "minio"

          env {
            name  = "MINIO_ROOT_USER"
            value = var.basic-username
          }

          env {
            name  = "MINIO_ROOT_PASSWORD"
            value = var.basic-password
          }

          port {
            container_port = 9000
          }

          port {
            container_port = 7000
          }

          args = ["server", "/data", "--console-address", ":7000"]
        }
      }
    }
  }
  depends_on = [kubernetes_namespace.minio_ns]
}

resource "kubernetes_service" "minio_svc" {
  metadata {
    name      = "minio-svc"
    namespace = kubernetes_namespace.minio_ns.metadata[0].name
  }
  spec {
    selector = {
      App = kubernetes_deployment.minio_deploy.spec[0].selector[0].match_labels.App
    }
    port {
      name        = "minio-api-port"
      port        = 9000
      target_port = 9000
    }
    port {
      name        = "minio-console-port"
      port        = 7000
      target_port = 7000
    }

    type = "ClusterIP"
  }
  depends_on = [kubernetes_deployment.minio_deploy]
}
