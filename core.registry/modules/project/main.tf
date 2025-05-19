// Project module: creates Entra group, federated credential, and ACR RBAC

locals {
  # Microsoft best practice: use lowercase, hyphens, and clear resource type prefixes
  # Example: group = "group-${var.project_name}-${each_env_name}"
  project_name_lower = lower(var.project_name)
  env_names          = var.environments
  group_names        = { for env in var.environments : env => "group-${local.project_name_lower}-${env}" }
  ado_app_name       = "spn-${local.project_name_lower}"
  federated_cred_name = "${local.project_name_lower}-ado-federated"
  dev_env_name       = length(local.env_names) > 0 ? local.env_names[0] : null
  dev_group_name     = local.dev_env_name != null ? local.group_names[local.dev_env_name] : null
  non_dev_env_names  = [for env in var.environments : env if env != local.dev_env_name]

  # Company-wide dev group for open ACR access
  company_dev_group_name = var.company_dev_group_name

  # Default values for issuer and subject, can be overridden by pipeline variables
  federated_issuer = "https://login.microsoftonline.com/{tenant_id}/v2.0"
  federated_subject = "api://{app_id}"
}

# Example usage for AzureAD group (one per environment)
resource "azuread_group" "devs" {
  for_each         = toset(var.environments)
  display_name     = local.group_names[each.key]
  security_enabled = true
}

resource "azuread_application" "ado_app" {
  display_name = local.ado_app_name
}

resource "azuread_service_principal" "ado_sp" {
  client_id = azuread_application.ado_app.client_id
}

resource "azuread_application_federated_identity_credential" "ado_federated" {
  application_id = azuread_application.ado_app.application_id
  display_name   = local.federated_cred_name
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = local.federated_issuer
  subject        = local.federated_subject
}

data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.acr_resource_group_name
}

# ACR RBAC assignments (per environment group)
resource "azurerm_role_assignment" "devs_pull" {
  count                = local.dev_env_name != null ? 1 : 0
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azuread_group.devs[local.dev_env_name].object_id
}

# Assign ACR pull to the federated credential (SP) for non-dev envs only
resource "azurerm_role_assignment" "ado_pull_non_dev" {
  for_each             = toset(local.non_dev_env_names)
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azuread_service_principal.ado_sp.object_id
}

resource "azurerm_role_assignment" "ado_push" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.ado_sp.object_id
}

resource "azurerm_role_assignment" "ado_sign" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrImageSigner"
  principal_id         = azuread_service_principal.ado_sp.object_id
}

# Company-wide dev group (open pull access)
data "azuread_group" "company_devs" {
  display_name = local.company_dev_group_name
}

resource "azurerm_role_assignment" "company_devs_pull" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = data.azuread_group.company_devs.object_id
}

data "azuredevops_project" "project" {
  name = var.project_name
}



# Create multiple environments and approvals
resource "azuredevops_environment" "env" {
  for_each  = toset(var.environments)
  project_id = data.azuredevops_project.project.id
  name       = each.key
}

resource "azuredevops_environment_approval" "group_approval" {
  for_each = toset(var.environments)
  project_id     = data.azuredevops_project.project.id
  environment_id = azuredevops_environment.env[each.key].id
  approver {
    type = "group"
    id   = azuread_group.devs[each.key].object_id
  }
}
