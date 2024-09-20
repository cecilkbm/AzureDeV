provider "azurerm" {
  features {}

  subscription_id = "00000000-0000-0000-0000-000000000000"
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
resource "azurerm_linux_virtual_machine" "ny_vm" {
  name                = "ny-office-vm"
  resource_group_name = azurerm_resource_group.east_rg.name
  location            = azurerm_resource_group.east_rg.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd123!"
  network_interface_ids = [azurerm_network_interface.ny_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
    source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# Virtual Machine in East US (Boston Office)
resource "azurerm_linux_virtual_machine" "boston_vm" {
  name                = "boston-office-vm"
  resource_group_name = azurerm_resource_group.east_rg.name
  location            = azurerm_resource_group.east_rg.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd123!"
  network_interface_ids = [azurerm_network_interface.boston_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
    source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# Virtual Machine in West US (Seattle Office)
resource "azurerm_linux_virtual_machine" "seattle_vm" {
  name                = "seattle-office-vm"
  resource_group_name = azurerm_resource_group.west_rg.name
  location            = azurerm_resource_group.west_rg.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd123!"
  network_interface_ids = [azurerm_network_interface.seattle_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
    source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

#Public IP address for East(NY)
resource "azurerm_public_ip" "eastny_ip" {
  name                = "newyork_office_publicip"
  resource_group_name = azurerm_resource_group.east_rg.name
  location            = azurerm_resource_group.east_rg.location
  allocation_method   = "Static"

  tags = {
    environment = "Development"
  }
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
