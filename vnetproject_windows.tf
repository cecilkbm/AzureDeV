provider "azurerm" {
  features {}

  subscription_id = "bdccc3a4-f427-4c00-af5f-cdbb1b3f5884"
}

# Resource Group for East US (New York and Boston offices)
resource "azurerm_resource_group" "east_rg" {
  name     = "east-office-rg"
  location = "East US"
}

# Resource Group for West US (Seattle office)
resource "azurerm_resource_group" "west_rg" {
  name     = "west-office-rg"
  location = "West US"
}

# VNet for East US region (New York office)
resource "azurerm_virtual_network" "east_vnetNY" {
  name                = "newyork-office-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.east_rg.location
  resource_group_name = azurerm_resource_group.east_rg.name
}

# VNet for East US region (Boston office)
resource "azurerm_virtual_network" "east_vnetMA" {
  name                = "boston-office-vnet"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.east_rg.location
  resource_group_name = azurerm_resource_group.east_rg.name
}

# VNet for West US region (Seattle office)
resource "azurerm_virtual_network" "west_vnet" {
  name                = "west-office-vnet"
  address_space       = ["10.3.0.0/16"]
  location            = azurerm_resource_group.west_rg.location
  resource_group_name = azurerm_resource_group.west_rg.name
}

# Subnet in East US (New York offices)
resource "azurerm_subnet" "east_subnet0" {
  name                 = "newyork-office-subnet"
  resource_group_name  = azurerm_resource_group.east_rg.name
  virtual_network_name = azurerm_virtual_network.east_vnetNY.name
  address_prefixes     = ["10.1.0.0/24"]
}

# Subnet in East US (Boston offices)
resource "azurerm_subnet" "east_subnet1" {
  name                 = "boston-office-subnet"
  resource_group_name  = azurerm_resource_group.east_rg.name
  virtual_network_name = azurerm_virtual_network.east_vnetMA.name
  address_prefixes     = ["10.2.0.0/24"]
}

# Subnet in West US (Seattle office)
resource "azurerm_subnet" "west_subnet" {
  name                 = "west-office-subnet"
  resource_group_name  = azurerm_resource_group.west_rg.name
  virtual_network_name = azurerm_virtual_network.west_vnet.name
  address_prefixes     = ["10.3.0.0/24"]
}

# VNet Peering: East(NY) to West
resource "azurerm_virtual_network_peering" "eastny_to_west" {
  name                      = "eastny-to-west-peering"
  resource_group_name        = azurerm_resource_group.east_rg.name
  virtual_network_name       = azurerm_virtual_network.east_vnetNY.name
  remote_virtual_network_id  = azurerm_virtual_network.west_vnet.id
  allow_virtual_network_access = true
}

# VNet Peering: West to East(NY)
resource "azurerm_virtual_network_peering" "west_to_eastny" {
  name                      = "west-to-eastny-peering"
  resource_group_name        = azurerm_resource_group.west_rg.name
  virtual_network_name       = azurerm_virtual_network.west_vnet.name
  remote_virtual_network_id  = azurerm_virtual_network.east_vnetNY.id
  allow_virtual_network_access = true
}

# VNet Peering: East(MA) to West
resource "azurerm_virtual_network_peering" "eastma_to_west" {
  name                      = "eastma-to-west-peering"
  resource_group_name        = azurerm_resource_group.east_rg.name
  virtual_network_name       = azurerm_virtual_network.east_vnetMA.name
  remote_virtual_network_id  = azurerm_virtual_network.west_vnet.id
  allow_virtual_network_access = true
}

# VNet Peering: West to East(MA)
resource "azurerm_virtual_network_peering" "west_to_eastma" {
  name                      = "west-to-eastma-peering"
  resource_group_name        = azurerm_resource_group.west_rg.name
  virtual_network_name       = azurerm_virtual_network.west_vnet.name
  remote_virtual_network_id  = azurerm_virtual_network.east_vnetMA.id
  allow_virtual_network_access = true
}

resource "azurerm_network_security_group" "east_nsg" {
  name                = "EastSecurityGroup"
  location            = azurerm_resource_group.east_rg.location
  resource_group_name = azurerm_resource_group.east_rg.name

  security_rule {
    name                       = "east0"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Development"
  }
}

resource "azurerm_network_security_group" "west_nsg" {
  name                = "WestSecurityGroup"
  location            = azurerm_resource_group.west_rg.location
  resource_group_name = azurerm_resource_group.west_rg.name

  security_rule {
    name                       = "west0"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Development"
  }
}

# Virtual Machine in East US (New York Office)
resource "azurerm_windows_virtual_machine" "ny_vm" {
  name                  = "ny-office-vm"
  location              = azurerm_resource_group.east_rg.location
  resource_group_name   = azurerm_resource_group.east_rg.name
  network_interface_ids = [azurerm_network_interface.ny_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  computer_name  = "hostname"
  admin_username = "adminuser"
  admin_password = "P@ssw0rd1234!"
}

# Virtual Machine in East US (Boston Office)
resource "azurerm_windows_virtual_machine" "boston_vm" {
  name                  = "boston-office-vm"
  location              = azurerm_resource_group.east_rg.location
  resource_group_name   = azurerm_resource_group.east_rg.name
  network_interface_ids = [azurerm_network_interface.boston_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  computer_name  = "hostname"
  admin_username = "adminuser"
  admin_password = "P@ssw0rd1234!"
}


# Virtual Machine in West US (Seattle Office)
resource "azurerm_windows_virtual_machine" "seattle_vm" {
  name                  = "seattle-office-vm"
  location              = azurerm_resource_group.west_rg.location
  resource_group_name   = azurerm_resource_group.west_rg.name
  network_interface_ids = [azurerm_network_interface.seattle_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  computer_name  = "hostname"
  admin_username = "adminuser"
  admin_password = "P@ssw0rd1234!"
}

# Network Interface for New York VM
resource "azurerm_network_interface" "ny_nic" {
  name                = "ny-office-nic"
  location            = azurerm_resource_group.east_rg.location
  resource_group_name = azurerm_resource_group.east_rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.east_subnet0.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          =  azurerm_public_ip.eastny_ip.id
  }
}

# Network Interface for Boston VM
resource "azurerm_network_interface" "boston_nic" {
  name                = "boston-office-nic"
  location            = azurerm_resource_group.east_rg.location
  resource_group_name = azurerm_resource_group.east_rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.east_subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Network Interface for Seattle VM
resource "azurerm_network_interface" "seattle_nic" {
  name                = "seattle-office-nic"
  location            = azurerm_resource_group.west_rg.location
  resource_group_name = azurerm_resource_group.west_rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.west_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Network Interface Subnet for New York NIC
resource "azurerm_subnet" "nynic_subnet" {
  name                 = "newyorknic-subnet"
  resource_group_name  = azurerm_resource_group.east_rg.name
  virtual_network_name = azurerm_virtual_network.east_vnetNY.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Interface Subnet for Boston NIC
resource "azurerm_subnet" "manic_subnet" {
  name                 = "bostonic-subnet"
  resource_group_name  = azurerm_resource_group.east_rg.name
  virtual_network_name = azurerm_virtual_network.east_vnetMA.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Network Interface Subnet for Seatle NIC
resource "azurerm_subnet" "wanic_subnet" {
  name                 = "seatlenic-subnet"
  resource_group_name  = azurerm_resource_group.west_rg.name
  virtual_network_name = azurerm_virtual_network.west_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}
