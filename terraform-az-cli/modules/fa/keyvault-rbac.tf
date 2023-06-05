################################################
#  Setting Key Vault RBAC Roles
################################################
resource "azurerm_role_assignment" "keyvaultadmin" {
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = "27eb37e9-55e8-4dde-b030-d93498737f50" # fridtjof
}

resource "azurerm_role_assignment" "keyvaultadmin1" {
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = azuread_service_principal.serviceprincipal.object_id 
}

resource "azurerm_role_assignment" "keyvaultsecretsofficer" {
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = "27eb37e9-55e8-4dde-b030-d93498737f50" # fridtjof
}