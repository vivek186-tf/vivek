provider "azurerm" {
    features {      
    }  
}

terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "=3.3.0"
    }
  }
}


# fetching exisitng resource group 

data "azurerm_resource_group" "vm-rg" {
  name = "trainingresourcegroup"
}

resource "tls_private_key" "pem-key" {
    algorithm = "RSA"
    rsa_bits = 4096  
}

resource "azurerm_ssh_public_key" "key-vivek" {
    name = "key-vivek"
    resource_group_name = data.azurerm_resource_group.vm-rg.name
    location = data.azurerm_resource_group.vm-rg.location
    public_key = tls_private_key.pem-key.public_key_openssh 
}


# fetching existing virtual network (vnet)


data "azurerm_virtual_network" "test-vn" {
    name = "publicvnet"
    resource_group_name = data.azurerm_resource_group.vm-rg.name

}

resource "azurerm_subnet" "vivek-subnet" {
  name = "vivek-subnet"
  resource_group_name =  data.azurerm_resource_group.vm-rg.name
  virtual_network_name =  data.azurerm_virtual_network.test-vn.name
  address_prefixes = ["172.16.8.0/24"]
}

data "azurerm_subnet" "subnet1" {
  name = "vivek-subnet"
  virtual_network_name = data.azurerm_virtual_network.test-vn.name
  resource_group_name = data.azurerm_resource_group.vm-rg.name
  depends_on = [azurerm_subnet.vivek-subnet]  
}

resource "azurerm_public_ip" "testip-vivek" {
  name = "testip-vivek"
  resource_group_name = data.azurerm_resource_group.vm-rg.name
  location = data.azurerm_resource_group.vm-rg.location
  allocation_method = "Static"

  tags = {
    "environment" = "testing-vivek"
  }  
}

resource "azurerm_network_interface" "test-ni-vivek" {
    name = "test-ni-vivek"
    resource_group_name = data.azurerm_resource_group.vm-rg.name
    location = data.azurerm_resource_group.vm-rg.location
    ip_configuration {
      name = "test-ni-ip-vivek"
      subnet_id = data.azurerm_subnet.subnet1.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id = azurerm_public_ip.testip-vivek.id
    }  
}


resource "azurerm_linux_virtual_machine" "vm-linux-vivek" {
  name = "vm-linux-vivek"
  resource_group_name = data.azurerm_resource_group.vm-rg.name
  location = data.azurerm_resource_group.vm-rg.location
  size = "Standard_F2"
  admin_username = "vivek"
  admin_password = "0valEdge!"

  custom_data = base64encode(file("user_data.sh"))

  network_interface_ids = [
    azurerm_network_interface.test-ni-vivek.id
  ]

  
  admin_ssh_key {
    username = "vivek"
    public_key = azurerm_ssh_public_key.key-vivek.public_key
  }

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "18.04-LTS"
    version = "latest"
  }

  disable_password_authentication = false
  
}

resource "azurerm_network_security_group" "test-sg-vivek" {
    name = "test-sg-vivek"
    resource_group_name = data.azurerm_resource_group.vm-rg.name
    location = data.azurerm_resource_group.vm-rg.location
    

    security_rule {
        name = "test-rule"
        priority = "100"
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "*"
        source_address_prefix = "*"
        destination_address_prefix = "*"

    }

    security_rule {
        name = "test-rule-ssh"
        priority = "200"
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "*"
        destination_address_prefix = "*"

    }

    tags = {
      "environemnt" = "testing-vivek"
    }
}

resource "azurerm_network_interface_security_group_association" "test-nsg-vivek" {
  network_interface_id = azurerm_network_interface.test-ni-vivek.id
  network_security_group_id = azurerm_network_security_group.test-sg-vivek.id

  depends_on = [
    azurerm_network_security_group.test-sg-vivek
  ]
  
}

resource "azurerm_mysql_server" "mysqlvi" {
  name                = "vi-mysql"
  location            = data.azurerm_resource_group.vm-rg.location
  resource_group_name = data.azurerm_resource_group.vm-rg.name
  administrator_login          = "sqladmin"
  administrator_login_password = "0valEdge!"
  sku_name   = "B_Gen5_2"
  storage_mb = 5120
  version    = "8.0"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = false
  infrastructure_encryption_enabled = false
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"
}

resource "azurerm_mysql_firewall_rule" "mysql_fw_rule" {
  name                = "mysql-fw-rule-allow-access"
  resource_group_name = data.azurerm_resource_group.vm-rg.name
  server_name         = azurerm_mysql_server.mysqlvi.name
  start_ip_address    = azurerm_linux_virtual_machine.vm-linux-vivek.public_ip_address
  end_ip_address      = azurerm_linux_virtual_machine.vm-linux-vivek.public_ip_address
}






