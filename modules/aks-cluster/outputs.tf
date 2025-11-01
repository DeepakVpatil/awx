output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.awx.name
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.awx.name
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.awx.kube_config
  sensitive   = true
}