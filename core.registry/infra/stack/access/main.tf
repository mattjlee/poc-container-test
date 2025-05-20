// Stack entrypoint for ACR access control (RBAC)

locals {
  project_keys = keys(var.projects)
}

module "projects" {
  for_each = var.projects
  source = "../../../modules/project"

  # Project-specific settings
  project_name               = each.value.project_name
  company_dev_group_name     = each.value.company_dev_group_name
  dev_group_name             = each.value.dev_group_name
  ado_service_principal_name = each.value.ado_service_principal_name
  environments               = each.value.environments
  azuredevops_project_name     = each.value.azuredevops_project_name 

  # Common settings from base object
  tenant_id                   = var.common_base.tenant_id
  subscription_id             = var.common_base.subscription_id
  azuredevops_org_service_url = var.common_base.azuredevops_org_service_url
  acr_name                    = var.common_base.acr_name
  acr_resource_group_name     = var.common_base.acr_resource_group_name
  azuredevops_pat_token       = var.common_base.azuredevops_pat_token
  
}
