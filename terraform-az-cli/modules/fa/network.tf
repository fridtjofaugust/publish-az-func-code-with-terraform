######################################################
# Create RG
######################################################
resource "azurerm_resource_group" "rg" {
  name     = "tf-vnet"
  location = "westeurope"
}


######################################################
# Create RG
######################################################
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}


######################################################
# Create integrationsubnet
######################################################
resource "azurerm_subnet" "integrationsubnet" {
  name                 = "integrationsubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
}


######################################################
# Create endpointsubnet
######################################################
resource "azurerm_subnet" "endpointsubnet" {
  name                                      = "endpointsubnet"
  resource_group_name                       = azurerm_resource_group.rg.name
  virtual_network_name                      = azurerm_virtual_network.vnet.name
  address_prefixes                          = ["10.0.2.0/24"]
  # private_endpoint_network_policies_enabled = true # defaults to true
}


################################################
#  Backend NSG
################################################
resource "azurerm_network_security_group" "endpoint" {
  name                = "${var.subscriptionname}-network-vnet-endpoint-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  # inbound
  security_rule {
    name                       = "AllowRDPfromTRDtoVNET"
    description                = "Allow RDP from TRD to VNet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "92.62.32.42" # TRD office IP
    destination_address_prefix = "VirtualNetwork"
  }
}


################################################
#  Associate Endpoint NSG with subnet
################################################
resource "azurerm_subnet_network_security_group_association" "endpoint" {
  subnet_id                 = azurerm_subnet.endpointsubnet.id
  network_security_group_id = azurerm_network_security_group.endpoint.id
}


######################################################
# App service  VNET swift connection
# ######################################################
# resource "azurerm_app_service_virtual_network_swift_connection" "vnetintegrationconnection" {
#   app_service_id = azurerm_function_app.function_app.id
#   subnet_id      = azurerm_subnet.integrationsubnet.id
# }