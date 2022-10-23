terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.21.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.1"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

provider "null" {
  # Configuration options
}

# VARS
#============================

variable "resource_group_name" {}

variable "location" {}

variable "subnet_id" {}

# WEB SERVER FQDN
#============================

resource "random_id" "webserver_dns" {
  byte_length = 8
}

# WEB SERVER PIP
#============================

resource "azurerm_public_ip" "cloudacademydevops-web-vm-pip" {
  name                = "cloudacademy-web-vm"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  domain_name_label   = "ca-labs-web-${lower(random_id.webserver_dns.hex)}"
}

# WEB SERVER NIC
#============================

resource "azurerm_network_interface" "cloudacademydevops-vm-nic" {
  name                = "cloudacademy-vm-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ip"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.cloudacademydevops-web-vm-pip.id
  }
}

# WEB SERVER CLOUDINIT TEMPLATE EXAMPLE
#============================

data "template_cloudinit_config" "vm_config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
    #! /bin/bash
    echo v1.00!
    echo example script only...
    EOF
  }
}

# WEBSERVER LINUX VM
#============================

resource "azurerm_linux_virtual_machine" "cloudacademy_web_vm" {
  name                  = "cloudacademy-web-vm"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.cloudacademydevops-vm-nic.id]
  size                  = "Standard_B1s"

  computer_name                   = "cloudacademy-vm"
  admin_username                  = "superadmin"
  admin_password                  = "s3cr3tP@55word"
  disable_password_authentication = false

  os_disk {
    name                 = "cloudacademy-vm-disk01"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  custom_data = data.template_cloudinit_config.vm_config.rendered

  tags = {
    org = "cloudacademy"
    app = "devops"
  }
}

# OUTPUTS
#============================

output "vm_public_ip" {
  value = azurerm_public_ip.cloudacademydevops-web-vm-pip.ip_address
}

output "vm_dns" {
  value = azurerm_public_ip.cloudacademydevops-web-vm-pip.fqdn
}
