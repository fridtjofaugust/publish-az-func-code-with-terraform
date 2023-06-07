################################################################################################
#  Parameters in this file needs to be changed
#
#  If deploying as a subsequent vm in the spoke you need to replace the "srv01" with "your_vm_name"
#
#  DO NOT INCLUDE TEST IN VM NAME
#
#
#
################################################################################################
variable "lin-srv01" {
  type    = string
  default = "lin-srv01" # Needs to be set
}

################################################
# Create Resource Group
################################################
resource "azurerm_resource_group" "lin-srv01" {
  name     = "${var.subscriptionname}-${var.lin-srv01}"
  location = var.location

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

################################################
# Create PIP
################################################
resource "azurerm_public_ip" "lin-srv01" {
  name                = "${var.subscriptionname}-lin-pip01"
  location            = azurerm_resource_group.lin-srv01.location
  resource_group_name = azurerm_resource_group.lin-srv01.name
  allocation_method   = "Static"
  sku                 = "Standard"
}



################################################
# Create Network Interface
################################################
resource "azurerm_network_interface" "lin-srv01" {
  name                = "${var.subscriptionname}-${var.lin-srv01}-nic00"
  location            = azurerm_resource_group.lin-srv01.location
  resource_group_name = azurerm_resource_group.lin-srv01.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.endpointsubnet.id # Needs to be set. Alternative is frontendsubnet or backendsubnet
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lin-srv01.id
  }
}



################################################
# Create Random Password
################################################
resource "random_password" "lin-srv01password" {
  length      = 16
  min_lower   = 4
  min_upper   = 4
  min_numeric = 4
  special     = false
  #override_special = "_%@"
}



################################################
# Create VM
################################################
resource "azurerm_linux_virtual_machine" "srv01" {
  name                            = "${var.subscriptionname}-${var.lin-srv01}"
  resource_group_name             = azurerm_resource_group.lin-srv01.name
  location                        = azurerm_resource_group.lin-srv01.location
  size                            = "Standard_DS1_v2" # Needs to be set 
  admin_username                  = "sysadmin"
  admin_password                  = "Vinter2016"
  disable_password_authentication = false
  zone                            = 1 # change if putting into a cluster 

  network_interface_ids = [
    azurerm_network_interface.lin-srv01.id,
  ]
  boot_diagnostics {
  }

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    name                 = "${var.subscriptionname}-${var.lin-srv01}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 64
  }

  # source_image_reference {
  #   publisher = "Canonical"
  #   offer     = "UbuntuServer"
  #   sku       = "18.04-LTS"
  #   version   = "latest"
  # }


    source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}



################################################
# Add secrets to Key Vault
################################################
# resource "azurerm_key_vault_secret" "srv01login" {
#   name         = "${var.lin-srv01}-LocalAdminLogin"
#   value        = azurerm_linux_virtual_machine.srv01.admin_username
#   key_vault_id = azurerm_key_vault.keyvault.id
# }
# resource "azurerm_key_vault_secret" "srv01password" {
#   name         = "${var.lin-srv01}-LocalAdminPassword"
#   value        = random_password.lin-srv01password.result
#   key_vault_id = azurerm_key_vault.keyvault.id
# }



################################################
# Auto-Shutdown of VM
################################################
resource "azurerm_dev_test_global_vm_shutdown_schedule" "lin-srv01" {
  virtual_machine_id    = azurerm_linux_virtual_machine.srv01.id
  location              = var.location
  enabled               = true
  daily_recurrence_time = "1615"
  timezone              = "W. Europe Standard Time"
  notification_settings {
    enabled = false
  }
}
