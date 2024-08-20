variable "location" {
  description = "The location of the resources."
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "The environment (e.g., dev, prod)."
  type        = string
   default     = "dev"

}


variable "vnet_config" {
  description = "Configuration for the virtual network and subnets."
  type = object({
    vnet_name       = string
    address_space   = list(string)
    subnets         = list(object({
      name             = string
      address_prefixes = list(string)
    }))
  })
  default = {
    vnet_name     = "vnet-aks"
    address_space = ["192.168.0.0/16"]
    subnets = [
      {
        name             = "snet-aks"
        address_prefixes = ["192.168.1.0/24"]
      },
      {
        name             = "snet-appgw"
        address_prefixes = ["192.168.2.0/24"]
      }
    ]
  }
}



variable "subnets" {
  type = list(object({
    name             = string
    address_prefixes = list(string)
  }))
  default = [
    {
      name             = "subnet_aks"
      address_prefixes = ["192.168.1.0/24"]
    },
    {
      name             = "subnet_appgw"
      address_prefixes = ["192.168.2.0/24"]
    }
  ]
}




resource "azurerm_resource_group" "rg" {
  location = var.location
  name     = "rg-${var.environment}"
}

resource "azurerm_virtual_network" "vn" {
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
#  name                = var.vnet_config.vnet_name
#  address_space       = var.vnet_config.address_space
 name = "harish"
 address_space = ["192.168.0.0/16"]
}

resource "azurerm_subnet" "subnet_aks" {
#  for_each            = { for subnet in var.vnet_config.subnets : subnet.name => subnet }
  count = length(var.subnets)
  resource_group_name = azurerm_resource_group.rg.name
  name                = var.subnets[count.index].name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes    = var.subnets[count.index].address_prefixes
}


output "subnet_ids" {
  value = [for s in azurerm_subnet.subnet_aks : s.id ]
}

