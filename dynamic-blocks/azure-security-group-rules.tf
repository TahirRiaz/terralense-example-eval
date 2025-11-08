terraform {
  required_version = ">= 0.12"
}

locals {
  security_rules = [
    {
      name        = "allow_http"
      priority    = 100
      direction   = "Inbound"
      port        = 80
      protocol    = "Tcp"
      source      = "*"
      destination = "*"
    },
    {
      name        = "allow_https"
      priority    = 101
      direction   = "Inbound"
      port        = 443
      protocol    = "Tcp"
      source      = "*"
      destination = "*"
    }
  ]
}

resource "azurerm_network_security_group" "example" {
  name                = "example-security-group"
  location            = "eastus"
  resource_group_name = "example-resources"

  dynamic "security_rule" {
    for_each = local.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = "Allow"
      protocol                   = security_rule.value.protocol
      source_port_range          = "*"
      destination_port_range     = security_rule.value.port
      source_address_prefix      = security_rule.value.source
      destination_address_prefix = security_rule.value.destination
    }
  }
}