locals {
  default_tags = var.custom_tags
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-network-rg"
  location = var.location

  tags = local.default_tags
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.vnets.main.address_space
  dns_servers         = var.vnets.main.dns_servers

  tags = local.default_tags
}

resource "azurerm_subnet" "main" {
  for_each = var.vnets.main.subnets

  name                 = "${each.value.no_prefix ? "" : var.prefix}${each.value.name_suffix}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints

  private_endpoint_network_policies             = each.value.private_endpoint_network_policies
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}
