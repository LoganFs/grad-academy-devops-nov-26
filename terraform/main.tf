terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116"
    }
  }
}

provider "azurerm" {
  features {}
  # Authentication comes from the Azure CLI. Run `az login` first and, if you
  # have more than one subscription, `az account set --subscription "<name>"`.
}

# The outermost box in the Mission 1 diagram: everything we create lives here,
# so teardown in Mission 5 is a single `terraform destroy`.
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg"
  location = var.location

  tags = local.tags
}

locals {
  tags = {
    project = "gta6-devops-academy"
    mission = "surviving-launch-day"
    managed = "terraform"
  }
}
