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

module "awx_infrastructure" {
  source = "../../modules/awx-infrastructure"
  
  environment           = "nonprod"
  location             = var.location
  node_count           = var.node_count
  vm_size              = var.vm_size
  kubernetes_version   = var.kubernetes_version
  awx_namespace        = "awx-nonprod"
  awx_operator_version = var.awx_operator_version
  
  tags = {
    Environment = "nonprod"
    Project     = "awx-control-tower"
  }
}

provider "kubernetes" {
  host                   = module.awx_infrastructure.kube_config.0.host
  client_certificate     = base64decode(module.awx_infrastructure.kube_config.0.client_certificate)
  client_key             = base64decode(module.awx_infrastructure.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(module.awx_infrastructure.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.awx_infrastructure.kube_config.0.host
    client_certificate     = base64decode(module.awx_infrastructure.kube_config.0.client_certificate)
    client_key             = base64decode(module.awx_infrastructure.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(module.awx_infrastructure.kube_config.0.cluster_ca_certificate)
  }
}