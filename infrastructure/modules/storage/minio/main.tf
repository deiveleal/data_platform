terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.5.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  config_context = "minikube"
}

resource "kubernetes_namespace" "minio_ns" {
  metadata {
    name = "minio-ns"
  }
}

# Aguardar MinIO estar pronto e criar buckets automaticamente
resource "null_resource" "create_buckets" {
  depends_on = [kubernetes_deployment.minio_deploy, kubernetes_service.minio_svc]
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "🚀 Aguardando MinIO ficar pronto..."
      kubectl wait --for=condition=ready pod -l App=Minio -n minio-ns --timeout=300s
      
      echo "⚙️ Configurando alias MinIO dentro do pod..."
      kubectl exec -n minio-ns deployment/minio-deploy -- mc alias set local http://localhost:9000 ${var.basic-username} ${var.basic-password}
      
      echo "📦 Criando buckets..."
      %{ for bucket in var.buckets_names ~}
      kubectl exec -n minio-ns deployment/minio-deploy -- mc mb local/${bucket} --ignore-existing
      echo "✅ Bucket '${bucket}' criado"
      %{ endfor ~}
      
      echo "🎉 Todos os buckets foram criados com sucesso!"
      kubectl exec -n minio-ns deployment/minio-deploy -- mc ls local
    EOT
  }
  
  # Remover buckets quando destruir a infraestrutura
  provisioner "local-exec" {
    when = destroy
    command = <<-EOT
      echo "🗑️ Removendo buckets..."
      for bucket in logs staging bronze silver gold; do
        kubectl exec -n minio-ns deployment/minio-deploy -- mc rb local/$bucket --force || true
        echo "🗑️ Bucket '$bucket' removido"
      done
    EOT
  }
  
  triggers = {
    buckets_hash = md5(join(",", var.buckets_names))
  }
}
