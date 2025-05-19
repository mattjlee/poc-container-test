output "dev_group_id" {
  value = azuread_group.devs.id
}

output "ado_service_principal_id" {
  value = azuread_service_principal.ado_sp.id
}
