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

resource "azurerm_resource_group" "awx" {
  name     = "rg-awx-${var.environment}"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "awx" {
  name                = "aks-awx-${var.environment}"
  location            = azurerm_resource_group.awx.location
  resource_group_name = azurerm_resource_group.awx.name
  dns_prefix          = "awx${var.environment}"

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.awx.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.awx.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.awx.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.awx.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.awx.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.awx.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.awx.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.awx.kube_config.0.cluster_ca_certificate)
  }
}

resource "kubernetes_namespace" "awx" {
  metadata {
    name = "awx"
  }
}

resource "helm_release" "awx_operator" {
  name       = "awx-operator"
  repository = "https://ansible.github.io/awx-operator/"
  chart      = "awx-operator"
  namespace  = kubernetes_namespace.awx.metadata[0].name

  depends_on = [azurerm_kubernetes_cluster.awx]
}