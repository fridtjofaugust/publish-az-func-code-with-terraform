################################################
#  Retrieve id of graph api service principal
################################################
data "azuread_application_published_app_ids" "graphapi" {}


################################################
#  Create Service Principal
################################################
resource "azuread_application" "serviceprincipal" {
  display_name = "${var.subscriptionname}-sp"
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