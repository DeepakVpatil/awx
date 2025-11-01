terraform {
  backend "azurerm" {
    # Configure these values or use environment variables
    # resource_group_name  = "rg-terraform-state"
    # storage_account_name = "terraformstate<unique>"
    # container_name       = "tfstate"
    # key                  = "awx/terraform.tfstate"
  }
}