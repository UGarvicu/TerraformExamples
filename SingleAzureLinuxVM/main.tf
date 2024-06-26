# Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.109.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

resource "azurerm_resource_group" "ugarvicursgroup" {
  name     = "ugarvicu-rsg"
  location = "West Europe"
}

resource "azurerm_virtual_network" "ugarvicuvnet" {
  name                = "ugarvicu-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.ugarvicursgroup.location
  resource_group_name = azurerm_resource_group.ugarvicursgroup.name
}

resource "azurerm_subnet" "ugarvicusubnet1" {
  name                 = "ugarvicu-subnet1"
  resource_group_name  = azurerm_resource_group.ugarvicursgroup.name
  virtual_network_name = azurerm_virtual_network.ugarvicuvnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "ugarvicunic" {
  name                = "ugarvicu-nic"
  location            = azurerm_resource_group.ugarvicursgroup.location
  resource_group_name = azurerm_resource_group.ugarvicursgroup.name

  ip_configuration {
    name                          = "ugarvicu-internal"
    subnet_id                     = azurerm_subnet.ugarvicusubnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "ugarvicuvm" {
  name                = "ugarvicu-example-linux-vm"
  resource_group_name = azurerm_resource_group.ugarvicursgroup.name
  location            = azurerm_resource_group.ugarvicursgroup.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.ugarvicunic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("C:/Users/Unai/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}