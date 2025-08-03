output "server-minio" {
  value = kubernetes_service.minio_svc.metadata[0].name
}

output "server-minio-ns" {
  value = kubernetes_namespace.minio_ns.metadata[0].name
}

output "server-minio-deploy" {
  value = kubernetes_deployment.minio_deploy.metadata[0].name
}

output "create_bucket" {
  value = var.buckets_names
  description = "List of buckets created automatically"
}

output "minio_endpoint" {
  value = <<-EOT
    MinIO Endpoints:
    
    🔗 API (S3):     kubectl port-forward -n ${kubernetes_namespace.minio_ns.metadata[0].name} svc/${kubernetes_service.minio_svc.metadata[0].name} 9000:9000
                     Then access: http://localhost:9000
    
    🖥️  Console:     kubectl port-forward -n ${kubernetes_namespace.minio_ns.metadata[0].name} svc/${kubernetes_service.minio_svc.metadata[0].name} 7000:7000
                     Then access: http://localhost:7000
    
    🔐 Credentials:  adminuser / adminuser
  EOT
  description = "Commands to access MinIO API and Console"
}