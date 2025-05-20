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
}

# Example usage for AzureAD group (one per environment)
resource "azuread_group" "devs" {
  for_each         = toset(var.environments)
  display_name     = replace(replace(local.group_name_template, "__PROJECT_NAME__", lower(var.project_name)), "__ENV__", each.key)
  security_enabled = true
}

resource "azuread_application" "ado_app" {
  for_each     = toset(var.environments)
  display_name = replace(replace(local.ado_app_name_template, "__PROJECT_NAME__", lower(var.project_name)), "__ENV__", each.key)
}

resource "azuread_service_principal" "ado_sp" {
  for_each = toset(var.environments)
  client_id = azuread_application.ado_app[each.key].client_id
}

resource "azurerm_user_assigned_identity" "env" {
  for_each            = toset(var.environments)
  name                = replace(replace(local.user_assigned_identity_name_template, "__PROJECT_NAME__", lower(var.project_name)), "__ENV__", each.key)
  resource_group_name = var.acr_resource_group_name
  location            = data.azurerm_container_registry.acr.location
}



# Static test federated identity credential for 'dev' environment only
resource "azurerm_federated_identity_credential" "ado_federated_dev" {
  name                = replace(replace(local.federated_cred_name_template, "__PROJECT_NAME__", lower(var.project_name)), "__ENV__", "dev")
  resource_group_name = var.acr_resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azuredevops_serviceendpoint_azurerm.federated["dev"].workload_identity_federation_issuer
  subject             = azuredevops_serviceendpoint_azurerm.federated["dev"].workload_identity_federation_subject
  parent_id           = azurerm_user_assigned_identity.env["dev"].id
}

# Commented out dynamic version for testing
# resource "azurerm_federated_identity_credential" "ado_federated" {
#   for_each            = toset(var.environments)
#   name                = replace(replace(local.federated_cred_name_template, "__PROJECT_NAME__", lower(var.project_name)), "__ENV__", each.key)
#   resource_group_name = var.acr_resource_group_name
#   audience            = ["api://AzureADTokenExchange"]
#   issuer              = azuredevops_serviceendpoint_azurerm.federated[each.key].workload_identity_federation_issuer
#   subject             = azuredevops_serviceendpoint_azurerm.federated[each.key].workload_identity_federation_subject
#   parent_id           = azurerm_user_assigned_identity.env[each.key].id
# }



data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.acr_resource_group_name
}

# ACR RBAC assignments
# Only dev environment gets push, pull, and sign
resource "azurerm_role_assignment" "dev_pull" {
  count                = length(var.environments) > 0 ? 1 : 0
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azuread_service_principal.ado_sp[var.environments[0]].object_id
}

resource "azurerm_role_assignment" "dev_push" {
  count                = length(var.environments) > 0 ? 1 : 0
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.ado_sp[var.environments[0]].object_id
}

resource "azurerm_role_assignment" "dev_sign" {
  count                = length(var.environments) > 0 ? 1 : 0
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrImageSigner"
  principal_id         = azuread_service_principal.ado_sp[var.environments[0]].object_id
}

# Non-prod and prod environments get pull only
resource "azurerm_role_assignment" "nondev_pull" {
  for_each = { for env in var.environments : env => env if env != var.environments[0] }
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azuread_service_principal.ado_sp[each.key].object_id
}

# Create a single developer group for ACR access (tracked by Terraform)
resource "azuread_group" "acr_developers" {
  display_name     = replace(local.acr_developers_group_name_template, "__PROJECT_NAME__", lower(var.project_name))
  security_enabled = true
}

# Assign AcrPull role to the tracked developer group
resource "azurerm_role_assignment" "acr_developers_pull" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azuread_group.acr_developers.object_id
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

# Service connection for each environment, using the user-assigned identity
resource "azuredevops_serviceendpoint_azurerm" "federated" {
  for_each                = toset(var.environments)
  project_id              = data.azuredevops_project.project.id
  service_endpoint_name   = replace(replace(local.service_endpoint_name_template, "__PROJECT_NAME__", lower(var.project_name)), "__ENV__", each.key)
  description             = "Federated identity service connection for ${var.project_name} (${each.key})"
  azurerm_spn_tenantid    = var.tenant_id
  azurerm_subscription_id = var.subscription_id
  azurerm_subscription_name = data.azurerm_subscription.selected.display_name
  credentials {
    serviceprincipalid = azurerm_user_assigned_identity.env[each.key].client_id
  }
}
