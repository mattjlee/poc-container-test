terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.15.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.50.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">= 1.5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "azurerm" {
  features {}
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "azuredevops" {
  org_service_url = var.azuredevops_org_service_url
  personal_access_token = var.azuredevops_pat_token
}
