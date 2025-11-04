# Non-Production Environment Configuration
environment = "nonprod"
namespace = "awx-nonprod"
replicas = 2
resource_requests = {
  cpu    = "200m"
  memory = "512Mi"
}
resource_limits = {
  cpu    = "1000m"
  memory = "1Gi"
}
storage_size = "10Gi"
auto_deploy = false
approval_required = true