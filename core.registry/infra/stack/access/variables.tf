variable "pull_principal_ids" {
  description = "List of object IDs (users/groups) allowed to pull from ACR."
  type        = list(string)
  default     = []
}

variable "push_principal_ids" {
  description = "List of object IDs (service principals/agents) allowed to push to ACR."
  type        = list(string)
  default     = []
}

variable "sensitive_acr_scope" {
  description = "The ACR resource ID or scope for the sensitive namespace/repo."
  type        = string
  default     = null
}

variable "federated_issuer" {
  description = "OIDC issuer for federated credential (ADO)."
  type        = string
}

variable "federated_subject" {
  description = "OIDC subject for federated credential (ADO)."
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

variable "tenant_id" {
  description = "The Azure Active Directory tenant ID."
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription ID."
  type        = string
}

variable "subscription_name" {
  description = "The Azure subscription name."
  type        = string
}

variable "azuread_client_id" {
  description = "The client ID for AzureAD provider authentication (optional)."
  type        = string
  default     = null
}

variable "azuread_client_secret" {
  description = "The client secret for AzureAD provider authentication (optional)."
  type        = string
  default     = null
  sensitive   = true
}

variable "azuread_client_cert_path" {
  description = "The path to the client certificate for AzureAD provider authentication (optional)."
  type        = string
  default     = null
}

variable "azuread_client_cert_password" {
  description = "The password for the client certificate (optional)."
  type        = string
  default     = null
  sensitive   = true
}

variable "azuredevops_org_service_url" {
  description = "The Azure DevOps organization service URL."
  type        = string
}

variable "azuredevops_pat_token" {
  description = "The Azure DevOps Personal Access Token (PAT)."
  type        = string
  sensitive   = true
}
