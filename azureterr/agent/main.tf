resource "azurerm_resource_group" "rg-devops" {
  name     = var.resource_group_name
  location = var.location
}

# Create Virtual Network
resource "azurerm_virtual_network" "agent-vnet" {
  name                = "linux-vnet"
  resource_group_name = azurerm_resource_group.rg-devops.name
  location            = azurerm_resource_group.rg-devops.location
  address_space       = ["10.0.0.0/16"]
}

# Create Subnet within the Virtual Network
resource "azurerm_subnet" "agent-subnet" {
  name                 = "internal1"
  resource_group_name  = azurerm_resource_group.rg-devops.name
  virtual_network_name = azurerm_virtual_network.agent-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
##Create The Virtual Machine
resource "azurerm_public_ip" "public_ip" {
  name                = "agentip"
  resource_group_name = azurerm_resource_group.rg-devops.name
  location            = var.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "main" {
  name                = "agent-nic"
  resource_group_name = azurerm_resource_group.rg-devops.name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.agent-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "ssh_nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-devops.name

  security_rule {
    name                       = "allow_ssh_sg"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_publicIP"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "association" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = var.agent_vm_name
  resource_group_name             = azurerm_resource_group.rg-devops.name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.main.id]

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

data "azurerm_public_ip" "public_ip" {
  name                = azurerm_public_ip.public_ip.name
  resource_group_name = azurerm_resource_group.rg-devops.name
  depends_on          = [azurerm_linux_virtual_machine.main]
}

output "ip_address" {
  value = data.azurerm_public_ip.public_ip.ip_address
}

## Install Docker and Configure Self-Hosted Agent
resource "null_resource" "install_docker" {
  provisioner "remote-exec" {
    inline = ["${file("script.sh")}"]
    #inline = ["${file("D:\\Nagarro\\Pramotions\\InfrastructureCode\\VM\\script.sh")}"]
    connection {
      type     = "ssh"
      user     = azurerm_linux_virtual_machine.main.admin_username
      password = azurerm_linux_virtual_machine.main.admin_password
      host     = data.azurerm_public_ip.public_ip.ip_address
      timeout  = "10m"
    }
  }
 triggers = {
    script_hash = "${filemd5("${path.module}/script.sh")}"
  }

}
