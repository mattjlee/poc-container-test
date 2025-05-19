// Stack entrypoint for core.registry infra

resource "azurerm_resource_group" "acr_rg" {
  name     = var.resource_group_name
  location = var.location
}

module "acr" {
  source              = "../../../modules/acr"
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.acr_rg.name
  location            = var.location
  sku                 = var.acr_sku
  tags                = var.tags
}
