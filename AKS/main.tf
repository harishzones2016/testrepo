# Define variables
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default=     "kopal"
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default =   "kopalnet"
}

variable "subnets" {
  description = "A map of subnets for the virtual network"
  type        = map(object({
    name           = string
    address_prefixes = string
  }))
  default     = {
    "subnet1" = {
      name           = "subnet1"
      address_prefixes = "192.168.1.0/24"
    }
    "subnet2" = {
      name           = "subnet2"
      address_prefixes = "192.168.2.0/24"
    }
  }
}
variable "nsg_rules" {
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  description = "The values for each NSG rule "
  default= [
  {
    name                       = "AllowWebIn"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  },
  {
    name                       = "AllowSSLIn"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  },
  {
    name                       = "AllowRDPIn"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
]

}
resource "azurerm_resource_group" "vnet_rg" {
  name     = var.resource_group_name
  location = "eastus"
#  tags     = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = ["192.168.0.0/16"]
  location            = azurerm_resource_group.vnet_rg.location
  resource_group_name = azurerm_resource_group.vnet_rg.name
#  tags                = var.tags
}

# Create subnets within the virtual network
resource "azurerm_subnet" "example" {
  for_each                    = var.subnets
  name                        = each.value.name
  resource_group_name         = azurerm_resource_group.vnet_rg.name
  virtual_network_name        = azurerm_virtual_network.vnet.name
  address_prefixes              = [each.value.address_prefixes]
}


resource "azurerm_network_security_group" "network_security_group" {
  name                = "sg"
  location            = azurerm_resource_group.vnet_rg.location
  resource_group_name = azurerm_resource_group.vnet_rg.name

  dynamic "security_rule" {
    for_each = var.nsg_rules
    content {
      name                       = security_rule.value["name"]
      priority                   = security_rule.value["priority"]
      direction                  = security_rule.value["direction"]
      access                     = security_rule.value["access"]
      protocol                   = security_rule.value["protocol"]
      source_port_range          = security_rule.value["source_port_range"]
      destination_port_range     = security_rule.value["destination_port_range"]
      source_address_prefix      = security_rule.value["source_address_prefix"]
      destination_address_prefix = security_rule.value["destination_address_prefix"]
    }
  }

 # tags = var.tags
}

