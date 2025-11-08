# Test: Azure Action Group Conditional
# Prefix: aag_ (azure_action_group)

variable "aag_action_group_mapping" {
  description = "Mapping of realms to action groups and email distribution lists"
  type = map(object({
    action_group_name = string
    email_receivers = optional(list(object({
      name          = string
      email_address = string
    })), [])
  }))

  default = {
    "default" = {
      action_group_name = "ag-default-kv-alerts"
      email_receivers = [
        {
          name          = "default_team"
          email_address = "default-team@tietoevery.com"
        }
      ]
    }
    "core" = {
      action_group_name = "ag-core-kv-alerts"
      email_receivers = [
        {
          name          = "core_team"
          email_address = "core-team@tietoevery.com"
        }
      ]
    }
  }
}

variable "aag_custom_tags" {
  type        = map(string)
  description = "Customer custom tags"
  default     = { test = "test", test2 = "test2" }
}

locals {
  aag_default_tags = var.aag_custom_tags
  aag_action_group_config = lookup(var.aag_action_group_mapping, "default", {
    action_group_name = ""
    email_receivers   = []
  })
  aag_action_group_defined = local.aag_action_group_config.action_group_name != "" ? true : false
}

resource "azurerm_resource_group" "aag_default" {
  name     = "local.prefix"
  location = "var.location"

  tags = local.aag_default_tags
}

resource "azurerm_monitor_action_group" "aag_secret_expiry" {
  count               = local.aag_action_group_defined ? 1 : 0
  id                  = "MyValue"
  name                = local.aag_action_group_config.action_group_name
  resource_group_name = azurerm_resource_group.aag_default.name
  short_name          = substr(replace(local.aag_action_group_config.action_group_name, "-", ""), 0, 12)

  dynamic "email_receiver" {
    for_each = local.aag_action_group_config.email_receivers

    content {
      name          = email_receiver.value.name
      email_address = email_receiver.value.email_address
    }
  }

  tags = local.aag_default_tags
}

resource "azurerm_resource_group" "aag_default2" {
  name     = "local.prefix2"
  location = "var.location2"

  tags = { test = azurerm_monitor_action_group.aag_secret_expiry[0].id }
}


output "aag_monitoring" {
  value = {
    action_group_default = {
      id = try(azurerm_monitor_action_group.aag_secret_expiry[0].id, null)
    }
  }
}