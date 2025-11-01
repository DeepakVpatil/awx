resource "azurerm_resource_group" "awx" {
  name     = "rg-awx-${var.environment}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_kubernetes_cluster" "awx" {
  name                = "aks-awx-${var.environment}"
  location            = azurerm_resource_group.awx.location
  resource_group_name = azurerm_resource_group.awx.name
  dns_prefix          = "awx${var.environment}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}