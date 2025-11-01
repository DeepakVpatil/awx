output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.awx.name
}

output "kubernetes_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.awx.name
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.awx.kube_config_raw
  sensitive   = true
}

output "cluster_endpoint" {
  description = "Kubernetes cluster endpoint"
  value       = azurerm_kubernetes_cluster.awx.kube_config.0.host
}