locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

module "aks_cluster" {
  source = "../aks-cluster"
  
  environment        = var.environment
  location          = var.location
  node_count        = var.node_count
  vm_size           = var.vm_size
  kubernetes_version = var.kubernetes_version
  
  tags = local.common_tags
}

module "awx_deployment" {
  source = "../awx-deployment"
  
  namespace        = var.awx_namespace
  operator_version = var.awx_operator_version
  
  depends_on = [module.aks_cluster]
}