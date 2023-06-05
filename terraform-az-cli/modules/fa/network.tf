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



######################################################
# Private endpoint to Backend app
######################################################
resource "azurerm_private_endpoint" "privateendpoint" {
  name                = "backwebappprivateendpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.endpointsubnet.id

  private_dns_zone_group {
    name                 = "privatednszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsprivatezone.id]
  }

  private_service_connection {
    name                           = "privateendpointconnection"
    private_connection_resource_id = azurerm_function_app.function_app.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}
