# Production Environment Configuration
environment = "prod"
namespace = "awx-prod"
replicas = 3
resource_requests = {
  cpu    = "500m"
  memory = "1Gi"
}
resource_limits = {
  cpu    = "2000m"
  memory = "2Gi"
}
storage_size = "20Gi"
auto_deploy = false
approval_required = true