variable "common_base" {
  description = "Common settings for tenant, subscription, ACR, and ADO org."
  type = object({
    tenant_id                   = string
    subscription_id             = string
    azuredevops_org_service_url = string
    acr_name                    = string
    acr_resource_group_name     = string
    azuredevops_pat_token       = string
  })
}

variable "projects" {
  description = "Map of project-specific parameters."
  type = map(object({
    project_name               = string
    company_dev_group_name     = string
    dev_group_name             = string
    ado_service_principal_name = string
    environments               = list(string)
    azuredevops_project_name   = string
  }))
}
