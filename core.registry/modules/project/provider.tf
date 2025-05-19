variable "tenant_id" {
  description = "The Azure Active Directory tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
}

variable "azuredevops_org_service_url" {
  description = "The Azure DevOps organization service URL"
  type        = string
}

variable "azuredevops_pat_token" {
  description = "The Azure DevOps personal access token"
  type        = string
  sensitive   = true
}

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
