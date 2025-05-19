// Stack entrypoint for ACR access control (RBAC)

# Example: Assign roles to users, groups, or service principals for ACR access
# resource "azurerm_role_assignment" "example" {
#   scope                = <acr_id>
#   role_definition_name = "AcrPull"
#   principal_id         = <object_id>
# }

module "example_project" {
  source = "../../../modules/project"

  project_name = "sampleapp"

  # Company-wide dev group for open ACR access
  company_dev_group_name = "devs-all"
  dev_group_name         = "devs-all"

  # Federated credential (ADO pipeline)
  ado_service_principal_name = "spn-sampleapp"

  # ACR lookup (abstracted from user, but pipeline injects these)
  acr_name                  = var.acr_name
  acr_resource_group_name   = var.acr_resource_group_name

  # Required attributes
  tenant_id                     = var.tenant_id
  azuredevops_org_service_url   = var.azuredevops_org_service_url
  subscription_id               = var.subscription_id
  azuredevops_pat_token         = var.azuredevops_pat_token

  environments = [
    "dev",
    "prod"
  ]
}
