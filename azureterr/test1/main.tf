resource "azurerm_resource_group" "homelabrg" {
/*
for_each = {
    "rsg1" = {name = "homelabdev", location = "eastus"}
    "rsg2" = {name = "homelabtest", location = "eastus"}
    "rsg3" = {name = "homelabstaging", location = "eastus"}
  }
*/
  for_each = var.rg
  name     = each.value.name
  location = each.value.location
}

      variable "rg" {
      type = map(object({
      name     = string
      location = string
    }))

default = {
rsg1 = {
      name     = "homelabdev"
      location = "eastus"
    }
    rsg2 = {
      name     = "homelabtest"
      location = "eastus"
    }
    rsg3 = {
      name     = "homelabstaging"
      location = "eastus"
    }
  }
}

