terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "aks_cluster" {
  source = "../../modules/aks-cluster"
  
  environment        = "dev"
  location          = var.location
  node_count        = var.node_count
  vm_size           = var.vm_size
  kubernetes_version = var.kubernetes_version
  
  tags = {
    Environment = "dev"
    Project     = "awx-control-tower"
  }
}

provider "kubernetes" {
  host                   = module.aks_cluster.kube_config.0.host
  client_certificate     = base64decode(module.aks_cluster.kube_config.0.client_certificate)
  client_key             = base64decode(module.aks_cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(module.aks_cluster.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.aks_cluster.kube_config.0.host
    client_certificate     = base64decode(module.aks_cluster.kube_config.0.client_certificate)
    client_key             = base64decode(module.aks_cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(module.aks_cluster.kube_config.0.cluster_ca_certificate)
  }
}

module "awx_deployment" {
  source = "../../modules/awx-deployment"
  
  namespace        = "awx-dev"
  operator_version = var.awx_operator_version
  
  depends_on = [module.aks_cluster]
}