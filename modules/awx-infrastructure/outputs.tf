output "kube_config" {
  description = "Kubernetes configuration"
  value       = module.aks_cluster.kube_config
  sensitive   = true
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = module.aks_cluster.cluster_name
}

output "resource_group_name" {
  description = "Resource group name"
  value       = module.aks_cluster.resource_group_name
}