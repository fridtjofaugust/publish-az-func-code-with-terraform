################################################
#  Retrieve id of graph api service principal
################################################
data "azuread_application_published_app_ids" "graphapi" {}


################################################
#  Create Service Principal
################################################
resource "azuread_application" "serviceprincipal" {
  display_name = "${var.subscriptionname}-sp-functionapp"
  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.graphapi.result.MicrosoftGraph
    resource_access {
      id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "msgraph" {
  application_id = data.azuread_application_published_app_ids.graphapi.result.MicrosoftGraph
  use_existing   = true
}

resource "azuread_service_principal" "serviceprincipal" {
  application_id = azuread_application.serviceprincipal.application_id
  feature_tags {
    enterprise = true
  }
}

resource "azuread_application_password" "serviceprincipal" {
  display_name          = "Github credential"
  application_object_id = azuread_application.serviceprincipal.object_id
}


################################################
# Add secrets to Key Vault
################################################
resource "azurerm_key_vault_secret" "serviceprincipalkey" {
  name         = "${azuread_application.serviceprincipal.display_name}-clientsecret"
  value        = azuread_application_password.serviceprincipal.value
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on = [
    azurerm_role_assignment.keyvaultadmin
  ]
}

resource "azurerm_key_vault_secret" "serviceprincipalid" {
  name         = "${azuread_application.serviceprincipal.display_name}-clientid"
  value        = azuread_application.serviceprincipal.application_id
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on = [
    azurerm_role_assignment.keyvaultadmin
  ]
}

resource "azurerm_key_vault_secret" "tenantid" {
  name         = "lab-tenantid"
  value        = data.azurerm_client_config.current.tenant_id
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on = [
    azurerm_role_assignment.keyvaultadmin
  ]
}


################################################
#  Add RBAC to subscription roles
################################################
resource "azurerm_role_assignment" "subscriptioncontributor-sp" {
  scope                = "/subscriptions/${var.subscriptionid}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.serviceprincipal.id
}