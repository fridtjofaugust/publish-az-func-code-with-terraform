################################################
# Create Resource Group
################################################
resource "azurerm_resource_group" "srv01" {
  name     = "${var.subscriptionname}-srv01"
  location = var.location
}



################################################
# Create Random Password
################################################
resource "random_password" "serverspassword-srv01" {
  length      = 16
  min_lower   = 4
  min_upper   = 4
  min_numeric = 4
  special     = false
  #override_special = "_%@"
}



################################################
# Create NIC
################################################
resource "azurerm_network_interface" "srv01" {
  name                = "${var.subscriptionname}-nic"
  location            = azurerm_resource_group.srv01.location
  resource_group_name = azurerm_resource_group.srv01.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.endpointsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.srv01.id
  }
}


################################################
# Create PIP
################################################
resource "azurerm_public_ip" "srv01" {
  name                = "${var.subscriptionname}-pip01"
  location            = azurerm_resource_group.srv01.location
  resource_group_name = azurerm_resource_group.srv01.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


################################################
# Create VM
################################################
resource "azurerm_windows_virtual_machine" "srv01" {
  name                = "${var.subscriptionname}-win-srv01"
  resource_group_name = azurerm_resource_group.srv01.name
  location            = azurerm_resource_group.srv01.location
  size                = "Standard_B2ms"
  admin_username      = "sysadmin"
  admin_password      = random_password.serverspassword-srv01.result
  network_interface_ids = [
    azurerm_network_interface.srv01.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  identity {
    type = "SystemAssigned"
    # identity_ids = [azurerm_user_assigned_identity.srv01.id]
  }
}

################################################
# Add secrets to Key Vault
################################################
resource "azurerm_key_vault_secret" "serverslogin-srv01" {
  name         = "${var.subscriptionname}-LocalAdminLogin-srv01"
  value        = azurerm_windows_virtual_machine.srv01.admin_username
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on = [
    azurerm_role_assignment.keyvaultadmin
  ]
}

resource "azurerm_key_vault_secret" "serverspassword-srv01" {
  name         = "${var.subscriptionname}-LocalAdminPassword-srv01"
  value        = random_password.serverspassword-srv01.result
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on = [
    azurerm_role_assignment.keyvaultadmin
  ]
}


################################################
# Auto-Shutdown of VM
################################################
resource "azurerm_dev_test_global_vm_shutdown_schedule" "srv01" {
  virtual_machine_id    = azurerm_windows_virtual_machine.srv01.id
  location              = var.location
  enabled               = true
  daily_recurrence_time = "1600"
  timezone              = "W. Europe Standard Time"
  notification_settings {
    enabled = false
  }
}



################################################
# VM extension AMA
################################################
# resource "azurerm_virtual_machine_extension" "azuremonitorwindowsagent-srv01" {
#   name                       = "AzureMonitorWindowsAgent"
#   publisher                  = "Microsoft.Azure.Monitor"
#   type                       = "AzureMonitorWindowsAgent"
#   type_handler_version       = 1.8
#   automatic_upgrade_enabled  = true
#   auto_upgrade_minor_version = "true"
#   virtual_machine_id         = azurerm_windows_virtual_machine.srv01.id

#   settings = jsonencode({
#     workspaceId               = azurerm_log_analytics_workspace.law.id
#     azureResourceId           = azurerm_windows_virtual_machine.srv01.id
#     stopOnMultipleConnections = false

#     authentication = {
#       managedIdentity = {
#         identifier-name  = "mi_res_id"
#         identifier-value = azurerm_user_assigned_identity.dcr.id
#       }
#     }
#   })
#   protected_settings = jsonencode({
#     "workspaceKey" = azurerm_log_analytics_workspace.law.primary_shared_key
#   })
# }



# ################################################
# # Windows VM Extensions Settings
# ################################################
# resource "azurerm_virtual_machine_extension" "da-srv01" {
#   name                       = "DAExtension"
#   virtual_machine_id         = azurerm_windows_virtual_machine.srv01.id
#   publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
#   type                       = "DependencyAgentWindows"
#   type_handler_version       = "9.10"
#   automatic_upgrade_enabled  = true
#   auto_upgrade_minor_version = true
# }



# ################################################
# # Associate VM to a Data Collection Rule
# ################################################
# resource "azurerm_monitor_data_collection_rule_association" "srv01" {
#   name                    = azurerm_monitor_data_collection_rule.dcr.name
#   target_resource_id      = azurerm_windows_virtual_machine.srv01.id
#   data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
# }
