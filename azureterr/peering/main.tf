resource "azurerm_resource_group" "main" {
  name     = "vnetrg1"
  location =  "eastus2"
}

resource "azurerm_virtual_network" "main" {
  name                = "linux1-network"
  address_space       = ["192.168.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_public_ip" "example" {
  name                = "linux1-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Dynamic"
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["192.168.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "linux1-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = "linux1-vm"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = "eastus2"
  size                            = "Standard_D2s_v3"
  admin_username                  = "adminuser"
  admin_password                  = "Negro@1234"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}








resource "azurerm_resource_group" "main1" {
  name     = "vnetrg2"
  location =  "westus"
}

resource "azurerm_virtual_network" "main1" {
  name                = "linux2-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main1.location
  resource_group_name = azurerm_resource_group.main1.name
}

resource "azurerm_public_ip" "example1" {
  name                = "linux2-pip"
  resource_group_name = azurerm_resource_group.main1.name
  location            = azurerm_resource_group.main1.location
  allocation_method   = "Dynamic"
}

resource "azurerm_subnet" "internal1" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main1.name
  virtual_network_name = azurerm_virtual_network.main1.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "main1" {
  name                = "linux2-nic"
  resource_group_name = azurerm_resource_group.main1.name
  location            = azurerm_resource_group.main1.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example1.id
  }
}

resource "azurerm_linux_virtual_machine" "main1" {
  name                            = "linux2-vm"
  resource_group_name             = azurerm_resource_group.main1.name
  location                        = "westus"
  size                            = "Standard_D2s_v3"
  admin_username                  = "adminuser"
  admin_password                  = "Negro@1234"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.main1.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}




resource "azurerm_virtual_network_peering" "peering1to2" {
  name                 = "peering1to2"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  remote_virtual_network_id = azurerm_virtual_network.main1.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "peering2to1" {
  name                 = "peering2to1"
  resource_group_name  = azurerm_resource_group.main1.name
  virtual_network_name = azurerm_virtual_network.main1.name
  remote_virtual_network_id = azurerm_virtual_network.main.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  use_remote_gateways       = false
}
