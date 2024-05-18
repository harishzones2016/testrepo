provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "uat"
  location = "East US"
}
