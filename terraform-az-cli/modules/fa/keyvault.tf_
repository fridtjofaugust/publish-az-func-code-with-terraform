data "azurerm_client_config" "current" {}

################################################
#  create RG
################################################
resource "azurerm_resource_group" "keyvault" {
  name     = "${var.subscriptionname}-keyvault"
  location = var.location
}


################################################
#  Deploy Spoke Key Vault
################################################
resource "azurerm_key_vault" "keyvault" {
  name                            = "${var.subscriptionname}${local.unique}-kv"
  location                        = azurerm_resource_group.keyvault.location
  resource_group_name             = azurerm_resource_group.keyvault.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days      = 90
  purge_protection_enabled        = false
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  enable_rbac_authorization       = true


  sku_name = "premium"
}