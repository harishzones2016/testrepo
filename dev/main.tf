provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "dev1"
  location = "East US"
}
