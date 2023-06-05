variable "project" {
  type = string
}

variable "location" {
  type = string
}

variable "os" {
  type = string
}

variable "hosting_plan" {
  type = string
}

variable "archive_file" {

}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.project}-resource-group"
  location = var.location
}

resource "azurerm_storage_account" "storage_account" {
  name                     = "${replace(var.project, "-", "")}strg${local.subshort}"
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "app_service_plan" {
  name                = "${var.project}-app-service-plan"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  kind                = var.hosting_plan == "premium" ? "elastic" : "FunctionApp"
  reserved            = var.os == "linux"
  sku {
    tier = var.hosting_plan == "premium" ? "ElasticPremium" : "Dynamic"
    size = var.hosting_plan == "premium" ? "EP1" : "Y1"
  }
}

resource "azurerm_function_app" "function_app" {
  name                = "${var.project}-function-app-lab"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  app_service_plan_id = azurerm_app_service_plan.app_service_plan.id
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"    = "1",
    "FUNCTIONS_WORKER_RUNTIME"    = "node",
    "AzureWebJobsDisableHomepage" = "true",
    "WEBSITE_NODE_DEFAULT_VERSION" : var.os == "windows" ? "~14" : null
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = "DefaultEndpointsProtocol=https;AccountName=tfpublishwinconsstrglab;AccountKey=37BA50XzrYyPBg9wCrh194feYV4GIRgbqugBFFpmbBiF4HYSnoRy7SgY7C+S6vlcfXTs1xoyslBd+ASt8Vbp6Q==;EndpointSuffix=core.windows.net"
    "WEBSITE_CONTENTSHARE"                     = "staging-content"
  }
  os_type = var.os == "linux" ? "linux" : null
  site_config {
    linux_fx_version          = var.os == "linux" ? "node|14" : null
    use_32_bit_worker_process = false
    elastic_instance_minimum  = 1 # had to be minimum 1
  }
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
  version                    = "~3"
}

locals {
  publish_code_command = "az webapp deployment source config-zip --resource-group ${azurerm_resource_group.resource_group.name} --name ${azurerm_function_app.function_app.name} --src ${var.archive_file.output_path}"
}

resource "null_resource" "function_app_publish" {
  provisioner "local-exec" {
    command = local.publish_code_command
  }
  depends_on = [local.publish_code_command]
  triggers = {
    input_json           = filemd5(var.archive_file.output_path)
    publish_code_command = local.publish_code_command
  }
}

output "function_app_default_hostname" {
  value = azurerm_function_app.function_app.default_hostname
}


################################################
# Create Random String
################################################
resource "random_string" "string" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}

################################################
# Create Random Password for sql admin
################################################
resource "random_password" "password" {
  length      = 16
  min_lower   = 4
  min_upper   = 4
  min_numeric = 4
  special     = false
  #override_special = "_%@"
}


locals {
  unique   = substr("${var.subscriptionid}", -5, -1)
  subshort = replace("${var.subscriptionname}", "-", "")
}

variable "subscriptionname" {
  type    = string
  default = "lab"
}

variable "subscriptionid" {
  type    = string
  default = "10a8bd0e-f9c0-4f29-9afa-1969c127608b"
}
