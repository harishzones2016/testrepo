variable "vm_names" {
  type    = list(string)
  default = ["linux-vm1", "linux-vm2"]
}

variable "pip_names" {
  type    = list(string)
  default = ["linux-pip1", "linux-pip2"]
}



variable "nic_names" {
  type    = list(string)
  default = ["linux-nic1", "linux-nic2"]
}

variable "vm" {
  type    = list(string)
  default = ["vm1", "vm2"]
}


variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "resource_group_name" {
  type    = string
  default = "vmgroup"
}

variable "vm_size" {
  type    = string
  default = "Standard_DS1_v2"
}


variable "network_security_group_name" {
  type    = string
  default = "nsgnew"
}


resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}


resource "azurerm_public_ip" "public_ip" {
#  for_each              = var.vm_names
   count  = length(var.pip_names)
   name                = var.pip_names[count.index]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"

  tags = {
    environment = "production"
  }
}



resource "azurerm_network_interface" "nic" {
#  for_each            = var.vm_names
#  name                = "${each.value}-nic"
   count  = length(var.nic_names)
   name                = var.nic_names[count.index]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip[count.index].id


  }
}




resource "azurerm_network_security_group" "nsg" {
  name                = var.network_security_group_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "production"
  }
}


resource "azurerm_network_interface_security_group_association" "association" {
 # for_each            = var.vm_names
  count  = length(var.nic_names)
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}




resource "azurerm_linux_virtual_machine" "vm" {
 # for_each            = var.vm_names
 # name                = each.value
  count  =              length(var.vm_names)
   name                = var.vm_names[count.index]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

/*
  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }
*/


os_disk {
     name                 = "myOsDisk-${count.index}"
     caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  #  create_option        = "FromImage"
  }

source_image_id = "/subscriptions/abb41ac5-f2f6-496b-ac03-bec3fd27a105/resourceGroups/example-rg/providers/Microsoft.Compute/images/myPackerImage"
  
/*
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
*/




  computer_name  =  "vm-${count.index}"
  disable_password_authentication = false
  admin_username                  = "azureuser"
  admin_password                  = "test@123"
/*
os_profile {
    computer_name  = "vm-${count.index}"
    admin_username = "adminuser"
    admin_password = "test@123"
  }
os_profile_linux_config {
    disable_password_authentication = false
  }
*/

  tags = {
    environment = "staging"
  }
}

output "vm_public_ips" {
  value = {
    for k, v in azurerm_linux_virtual_machine.vm : k => v.public_ip_address
  }
}
