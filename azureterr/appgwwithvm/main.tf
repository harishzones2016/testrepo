# 1. Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "example-westus"
  location = "westus"
}

# 2. Create Virtual Network and Subnets
resource "azurerm_virtual_network" "vnet" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 3. Create a Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "example-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
/*
# 4. Associate NSG with the Subnet
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
*/

# 5. Create Public IP Address for Application Gateway
resource "azurerm_public_ip" "appgw_public_ip" {
  name                = "example-appgw-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# 6. Create Network Interface for the Linux VM
resource "azurerm_network_interface" "webvm_nic" {
  name                = "example-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}



resource "azurerm_network_interface_security_group_association" "linux" {
  network_interface_id      = azurerm_network_interface.webvm_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  backend_address_pool_id = azurerm_application_gateway.appgw.backend_address_pool[0].id
}


# 7. Create Linux Virtual Machine (Web VM) and Install Nginx
resource "azurerm_linux_virtual_machine" "webvm" {
  name                = "example-webvm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  admin_password      = "test@1234"

  network_interface_ids = [
    azurerm_network_interface.webvm_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }


custom_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              systemctl enable nginx
              systemctl start nginx
              EOF
  )

}

# 8. Create Application Gateway
resource "azurerm_application_gateway" "appgw" {
  name                = "example-appgw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-config"
    subnet_id = azurerm_subnet.subnet.id
  }

  frontend_ip_configuration {
    name                 = "my-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw_public_ip.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }


  backend_address_pool {
    name = "my-backend-pool"
  #  backend_address {
  #    ip_address = azurerm_linux_virtual_machine.webvm.private_ip_address
  #  }
  }


  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "my-listener"
    frontend_ip_configuration_name = "my-frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rule1"
    rule_type                  = "Basic"
    http_listener_name         = "my-listener"
    backend_address_pool_name  = "my-backend-pool"
    backend_http_settings_name = "http-settings"
  }
}
/*
# 9. Add Backend Pool to Application Gateway
resource "azurerm_application_gateway_backend_address_pool" "backend_pool" {
  name                = "example-backend-pool"
  resource_group_name = azurerm_resource_group.rg.name
  application_gateway_name = azurerm_application_gateway.appgw.name
  backend_addresses {
    ip_address = azurerm_network_interface.webvm_nic.private_ip_address
  }
}
*/
