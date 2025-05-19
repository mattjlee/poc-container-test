# Registry Stack: Azure Container Registry

This stack provisions the Azure Container Registry (ACR) for the core.registry POC.

## Usage
1. Update `variables.tf` or provide variables via CLI or `.tfvars`.
2. Initialize and apply the stack:
   ```sh
   az login
   az account set --subscription <your-subscription-id>
   terraform init
   terraform plan
   terraform apply
   ```

## Outputs
- `acr_id`: The resource ID of the ACR
- `acr_login_server`: The login server URL for the ACR
