# Development Environment Configuration
environment = "dev"
namespace = "awx-dev"
replicas = 1
resource_requests = {
  cpu    = "100m"
  memory = "256Mi"
}
resource_limits = {
  cpu    = "500m"
  memory = "512Mi"
}
storage_size = "5Gi"
auto_deploy = true
approval_required = false