variable "prefix" {
  type        = string
  description = "Prefix to be applied to all resources"
  default     = "demo"
}

variable "location" {
  type        = string
  description = "Default location for all resources"
  default     = "eastus"
}

variable "custom_tags" {
  type        = map(string)
  description = "Custom tags to apply to all resources"
  default = {
    managed_by = "Terraform"
    owner      = "Platform Team"
  }
}

variable "vnets" {
  description = "Virtual networks and their subnets"
  type = map(object({
    address_space = list(string)
    dns_servers   = optional(list(string), [])
    subnets = map(object({
      name_suffix                                   = string
      no_prefix                                     = optional(bool, false)
      address_prefixes                              = list(string)
      service_endpoints                             = optional(list(string), [])
      private_endpoint_network_policies             = optional(string, "Enabled")
      private_link_service_network_policies_enabled = optional(bool, true)
      nat_gateway_association                       = optional(bool, false)
      delegation = optional(object({
        name = string
        service_delegation = object({
          name    = string
          actions = list(string)
        })
      }), null)
    }))
  }))

  default = {
    main = {
      address_space = ["10.50.0.0/16"]
      dns_servers   = []
      subnets = {
        app_public = {
          address_prefixes = ["10.50.10.0/26"]
          name_suffix      = "-app-public-sn"
          delegation = {
            name = "container-delegation-public"
            service_delegation = {
              name = "Microsoft.Databricks/workspaces"
              actions = [
                "Microsoft.Network/virtualNetworks/subnets/join/action",
                "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
                "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
              ]
            }
          }
          nat_gateway_association = true
          service_endpoints       = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault"]
        }
        app_private = {
          address_prefixes = ["10.50.10.64/26"]
          name_suffix      = "-app-private-sn"
          delegation = {
            name = "container-delegation-private"
            service_delegation = {
              name = "Microsoft.Databricks/workspaces"
              actions = [
                "Microsoft.Network/virtualNetworks/subnets/join/action",
                "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
                "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
              ]
            }
          }
          nat_gateway_association = true
        }
        endpoints = {
          address_prefixes                              = ["10.50.20.0/24"]
          name_suffix                                   = "-endpoints-sn"
          private_endpoint_network_policies             = "Disabled"
          private_link_service_network_policies_enabled = false
        }
        services = {
          address_prefixes                              = ["10.50.10.128/28"]
          name_suffix                                   = "-services-sn"
          private_endpoint_network_policies             = "Disabled"
          private_link_service_network_policies_enabled = false
        }
      }
    }
  }
}
