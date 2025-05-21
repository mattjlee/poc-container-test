// Project module: creates Entra group, federated credential, and ACR RBAC

locals {
  # Syntax/naming conventions as static templates (do not reference other locals)
  group_name_template                = "group-__PROJECT_NAME__-__ENV__"
  ado_app_name_template              = "spn-__PROJECT_NAME__-__ENV__"
  federated_cred_name_template       = "__PROJECT_NAME__-ado-federated-__ENV__"
  acr_developers_group_name_template = "acr-developers-__PROJECT_NAME__"
  user_assigned_identity_name_template = "id-__PROJECT_NAME__-__ENV__"
  azuredevops_env_name_template      = "__PROJECT_NAME__-__ENV__"
  service_endpoint_name_template     = "__PROJECT_NAME__-federated-__ENV__"
  build_service_endpoint_name        = "__PROJECT_NAME__-federated-build"
  build_user_assigned_identity_name  = "id-__PROJECT_NAME__-build"
  build_federated_cred_name          = "__PROJECT_NAME__-ado-federated-build"
}

# Example usage for AzureAD group (one per environment)
resource "azuread_group" "devs" {
  for_each         = toset(var.environments)
  display_name     = replace(replace(local.group_name_template, "__PROJECT_NAME__", lower(var.project_name)), "__ENV__", each.key)
  security_enabled = true
}

# Managed identity for each environment
resource "azurerm_user_assigned_identity" "env" {
  for_each            = toset(var.environments)
  name                = replace(replace(local.user_assigned_identity_name_template, "__PROJECT_NAME__", lower(var.project_name)), "__ENV__", each.key)
  resource_group_name = var.acr_resource_group_name
  location            = data.azurerm_container_registry.acr.location
}

# Managed identity for build (common to all projects)
resource "azurerm_user_assigned_identity" "build" {
  name                = replace(local.build_user_assigned_identity_name, "__PROJECT_NAME__", lower(var.project_name))
  resource_group_name = var.acr_resource_group_name
  location            = data.azurerm_container_registry.acr.location
}

# # Service connection for each environment (pull only)
# resource "azuredevops_serviceendpoint_azurerm" "federated_env" {
#   for_each                = toset(var.environments)
#   project_id              = data.azuredevops_project.project.id
#   service_endpoint_name   = replace(replace(local.service_endpoint_name_template, "__PROJECT_NAME__", lower(var.project_name)), "__ENV__", each.key)
#   description             = "Federated identity service connection for ${var.project_name} (${each.key})"
#   azurerm_spn_tenantid    = var.tenant_id
#   azurerm_subscription_id = var.subscription_id
#   azurerm_subscription_name = data.azurerm_subscription.selected.display_name
#   credentials {
#     serviceprincipalid = azurerm_user_assigned_identity.env[each.key].client_id
#   }
# }

# Service connection for build (push, pull, sign)
resource "azuredevops_serviceendpoint_azurerm" "federated_build" {
  project_id              = data.azuredevops_project.project.id
  service_endpoint_name   = replace(local.build_service_endpoint_name, "__PROJECT_NAME__", lower(var.project_name))
  description             = "Federated identity service connection for ${var.project_name} (build)"
  azurerm_spn_tenantid    = var.tenant_id
  azurerm_subscription_id = var.subscription_id
  azurerm_subscription_name = data.azurerm_subscription.selected.display_name
  credentials {
    serviceprincipalid = azurerm_user_assigned_identity.build.client_id
  }
}

# # Federated identity credential for each environment
# resource "azurerm_federated_identity_credential" "ado_federated_env" {
#   for_each            = toset(var.environments)
#   name                = replace(replace(local.federated_cred_name_template, "__PROJECT_NAME__", lower(var.project_name)), "__ENV__", each.key)
#   resource_group_name = var.acr_resource_group_name
#   audience            = ["api://AzureADTokenExchange"]
#   issuer              = azuredevops_serviceendpoint_azurerm.federated_env[each.key].workload_identity_federation_issuer
#   subject             = azuredevops_serviceendpoint_azurerm.federated_env[each.key].workload_identity_federation_subject
#   parent_id           = azurerm_user_assigned_identity.env[each.key].id

# }

# Federated identity credential for build
resource "azurerm_federated_identity_credential" "ado_federated_build" {
  name                = replace(local.build_federated_cred_name, "__PROJECT_NAME__", lower(var.project_name))
  resource_group_name = var.acr_resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azuredevops_serviceendpoint_azurerm.federated_build.workload_identity_federation_issuer
  subject             = azuredevops_serviceendpoint_azurerm.federated_build.workload_identity_federation_subject
  parent_id           = azurerm_user_assigned_identity.build.id
}

data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.acr_resource_group_name
}

# ACR RBAC assignments
# Environments: pull only
resource "azurerm_role_assignment" "env_pull" {
  for_each            = toset(var.environments)
  scope               = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id        = azurerm_user_assigned_identity.env[each.key].principal_id
}

# Build: pull, push, sign
resource "azurerm_role_assignment" "build_pull" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.build.principal_id
}
resource "azurerm_role_assignment" "build_push" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.build.principal_id
}
resource "azurerm_role_assignment" "build_sign" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrImageSigner"
  principal_id         = azurerm_user_assigned_identity.build.principal_id
}

# Remove project_name dependency from ADO project data source
# Use a variable for the ADO project name, not tied to the project_name

variable "azuredevops_project_name" {
  description = "The name of the Azure DevOps project to use for service connections and environments."
  type        = string
}

data "azuredevops_project" "project" {
  name = var.azuredevops_project_name
}

# Create multiple environments
resource "azuredevops_environment" "env" {
  for_each  = toset(var.environments)
  project_id = data.azuredevops_project.project.id
  name       = replace(replace(local.azuredevops_env_name_template, "__PROJECT_NAME__", lower(var.project_name)), "__ENV__", each.key)
}

data "azurerm_subscription" "current" {}

data "azurerm_subscription" "selected" {
  subscription_id = var.subscription_id
}


