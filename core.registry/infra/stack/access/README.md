# Access Stack: ACR RBAC

This stack manages RBAC (role-based access control) for Azure Container Registry (ACR).

## Usage
- Pass the ACR resource ID and lists of principal IDs for pull/push access.
- Example variables:
  - `acr_id`: Resource ID of the ACR (output from registry stack)
  - `pull_principal_ids`: List of object IDs (users/groups) allowed to pull
  - `push_principal_ids`: List of object IDs (service principals/agents) allowed to push

## Example
```
variable "acr_id" {}
variable "pull_principal_ids" {}
variable "push_principal_ids" {}
```

## Next Steps
- Add `azurerm_role_assignment` resources for each principal as needed.
