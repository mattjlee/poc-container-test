variable "project_name" {
  description = "The name of the project."
  type        = string
}


variable "dev_group_name" {
  description = "The display name for the developers' Entra group."
  type        = string
}

variable "ado_service_principal_name" {
  description = "The display name for the ADO federated credential app."
  type        = string
}

variable "federated_issuer" {
  description = "OIDC issuer for federated credential (ADO). If not set, should be injected by pipeline."
  type        = string
  default     = null
}

variable "federated_subject" {
  description = "OIDC subject for federated credential (ADO). If not set, should be injected by pipeline."
  type        = string
  default     = null
}

variable "company_dev_group_name" {
  description = "Display name of the company-wide AzureAD group for open ACR pull access."
  type        = string
}

variable "acr_name" {
  description = "The name of the Azure Container Registry."
  type        = string
}

variable "acr_resource_group_name" {
  description = "The name of the resource group containing the ACR."
  type        = string
}

variable "environments" {
  description = "List of environment names to create (e.g., [\"dev\", \"prod\"]). Approval groups will be created for each."
  type        = list(string)
  default     = []
}


