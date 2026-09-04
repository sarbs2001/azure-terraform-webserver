terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rgroup" {
  name     = "rgroup-dev"
  location = "West US 2"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-dev"
  resource_group_name = azurerm_resource_group.rgroup.name
  location            = azurerm_resource_group.rgroup.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet_1" {
  name                 = "subnet_1"
  resource_group_name  = azurerm_resource_group.rgroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet_2" {
  name                 = "subnet_2"
  resource_group_name  = azurerm_resource_group.rgroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "subnet_3" {
  name                 = "subnet_3"
  resource_group_name  = azurerm_resource_group.rgroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_network_security_group" "s1_nsg" {
  name                = "subnet1_nsg"
  location            = azurerm_resource_group.rgroup.location
  resource_group_name = azurerm_resource_group.rgroup.name
}

resource "azurerm_network_security_group" "s2_nsg" {
  name                = "subnet2_nsg"
  location            = azurerm_resource_group.rgroup.location
  resource_group_name = azurerm_resource_group.rgroup.name
}

resource "azurerm_network_security_group" "s3_nsg" {
  name                = "subnet3_nsg"
  location            = azurerm_resource_group.rgroup.location
  resource_group_name = azurerm_resource_group.rgroup.name
}

resource "azurerm_network_security_rule" "s1_rule" {
  name                        = "rule_1"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rgroup.name
  network_security_group_name = azurerm_network_security_group.s1_nsg.name
}

resource "azurerm_network_security_rule" "s2_rule" {
  name                        = "rule_1"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rgroup.name
  network_security_group_name = azurerm_network_security_group.s2_nsg.name
}

resource "azurerm_network_security_rule" "s3_rule" {
  name                        = "rule_1"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rgroup.name
  network_security_group_name = azurerm_network_security_group.s3_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "s1_association" {
  subnet_id                 = azurerm_subnet.subnet_1.id
  network_security_group_id = azurerm_network_security_group.s1_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "s2_association" {
  subnet_id                 = azurerm_subnet.subnet_2.id
  network_security_group_id = azurerm_network_security_group.s2_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "s3_association" {
  subnet_id                 = azurerm_subnet.subnet_3.id
  network_security_group_id = azurerm_network_security_group.s3_nsg.id
}

resource "azurerm_public_ip" "public_ip" {
  name                = "public_ip"
  resource_group_name = azurerm_resource_group.rgroup.name
  location            = azurerm_resource_group.rgroup.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic_subnet_1" {
  name                = "nic_subnet_1"
  location            = azurerm_resource_group.rgroup.location
  resource_group_name = azurerm_resource_group.rgroup.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "s1_vm" {
  name                = "subnet1-vm"
  resource_group_name = azurerm_resource_group.rgroup.name
  location            = azurerm_resource_group.rgroup.location
  size                = "Standard_D2ps_v6"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nic_subnet_1.id
  ]

  custom_data = filebase64("docker.tpl")

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("/Users/sarbjotsingh/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server-arm64"
    version   = "latest"
  }

  provisioner "local-exec" {
    command = templatefile("linux-ssh-script.tpl", {
      hostname     = self.public_ip_address,
      user         = "adminuser"
      identityfile = "~/.ssh/id_rsa"
    })
    interpreter = ["/bin/zsh", "-c"]
  }
}


