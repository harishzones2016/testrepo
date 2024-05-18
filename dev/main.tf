provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "dev"
  location = "East US"
}
