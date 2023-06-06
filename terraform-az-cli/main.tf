terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Root module should specify the maximum provider version
      # The ~> operator is a convenient shorthand for allowing only patch releases within a specific minor release.
      version = "~> 2.26"
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
