# Project Module

This module provisions:
- An Entra (Azure AD) group for developers (pull access)
- A federated credential (ADO pipeline/service principal) with pull, push, and sign access
- ACR RBAC assignments for both

## Inputs
- `project_name`: Name of the project
- `acr_id`: Resource ID of the ACR
- `dev_group_name`: Name for the dev group
- `ado_service_principal_name`: Name for the federated credential app
- `federated_issuer`: OIDC issuer for ADO
- `federated_subject`: OIDC subject for ADO

## Outputs
- `dev_group_id`
- `ado_service_principal_id`

## Note
ADO environment and group approval can be added via external provider or script.
