terraform {

    backend "azurerm" {
    resource_group_name  = "lab-terraform"
    storage_account_name = "labtfstatepcxe0v"
    container_name       = "p-terra"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true
  }
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Root module should specify the maximum provider version
      # The ~> operator is a convenient shorthand for allowing only patch releases within a specific minor release.
      version = "~> 3.58"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4.3"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.33.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  location = "westeurope"
}


# creates an archive file named "file_function_app" by zipping the contents of the "../function-app" directory and assigns it to the data.archive_file.file_function_app attribute.
data "archive_file" "file_function_app" {
  type        = "zip"
  source_dir  = "../function-app"
  output_path = "function-app.zip"
}


# defines characteristics of the function app
module "linux_premium" {
  source = "./modules/fa"

  project      = "tf-publish-lin-pre"
  location     = local.location
  os           = "linux"
  hosting_plan = "premium"
  archive_file = data.archive_file.file_function_app
}

# module "linux_consumption" {
#   source = "./modules/fa"

#   project      = "tf-publish-lin-cons"
#   location     = local.location
#   os           = "linux"
#   hosting_plan = "consumption"
#   archive_file = data.archive_file.file_function_app
# }

# module "windows_premium" {
#   source = "./modules/fa"

#   project      = "tf-publish-win-pre"
#   location     = local.location
#   os           = "windows"
#   hosting_plan = "premium"
#   archive_file = data.archive_file.file_function_app
# }

# module "windows_consumption" {
#   source = "./modules/fa"

#   project      = "tf-publish-win-cons"
#   location     = local.location
#   os           = "windows"
#   hosting_plan = "consumption"
#   archive_file = data.archive_file.file_function_app
# }

output "linux_premium_hostname" {
  value = module.linux_premium.function_app_default_hostname
}

# output "linux_consumption_hostname" {
#   value = module.linux_consumption.function_app_default_hostname
# }

# output "windows_premium_hostname" {
#   value = module.windows_premium.function_app_default_hostname
# }

# output "windows_consumption_hostname" {
#   value = module.windows_consumption.function_app_default_hostname
# }


################################################
# Create Resource Group
################################################
resource "azurerm_resource_group" "resource_group_web" {
  name     = "tf-resource-group"
  location = "westeurope"
}


################################################
# Create service plan
################################################
resource "azurerm_service_plan" "webapps" {
  name                = "lab-webapps-plan"
  resource_group_name = azurerm_resource_group.resource_group_web.name
  location            = azurerm_resource_group.resource_group_web.location
  os_type             = "Linux"
  sku_name            = "S1" # Basic: 1 core, 1.75 GB ram. Options: B1 B2 B3 S1 S2 S3 P1v2 P2v2 P3v2 P1v3 P2v3 P3v3
}



################################################
# Create linux service app
################################################
resource "azurerm_linux_web_app" "web_app" {
  name                = "web-app-service-zipdeploy"
  location            = azurerm_resource_group.resource_group_web.location
  resource_group_name = azurerm_resource_group.resource_group_web.name
  service_plan_id     = azurerm_service_plan.webapps.id

  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE       = "1"
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
  }

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }
  zip_deploy_file = "./function-app.zip"
}
