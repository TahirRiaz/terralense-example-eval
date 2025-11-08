# Test: Try Lookup Realm Selection
# Prefix: tlr_ (try_lookup_realm)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

variable "tlr_secret_expiry_alert_config" {
  description = "test"

  type = list(object({
    realm             = string
    action_group_name = string
    email_recipients = list(object({
      name  = string
      email = string
    }))
  }))

  // Example realms. Must be defined globally or provided externally
  default = [
    {
      realm             = "default"
      action_group_name = "ag-default-kv-alerts"
      email_recipients = [
        { name = "Default Admin", email = "default-admin@example.com" }
      ]
    },
    {
      realm             = "base"
      action_group_name = "ag-base-kv-alerts"
      email_recipients = [
        { name = "Base Admin", email = "base-admin@example.com" }
      ]
    },
    // ... Additional realms ...
  ]
}

variable "tlr_secret_expiry_alert" {
  description = "Configuration object controlling Key Vault secret-expiry monitoring and alerting."

  type = object({
    realm = optional(string, null)

    additional_email_recipients = optional(list(object({
      name  = string
      email = string
    })), [])

    log_analytics_workspace_id = optional(string, null)

    max_delivery_attempts = optional(number, 3)
  })

  default = null

  validation {
    condition     = var.tlr_secret_expiry_alert == null || var.tlr_secret_expiry_alert.realm == null ? true : var.tlr_secret_expiry_alert.log_analytics_workspace_id != null
    error_message = "When a valid realm is specified, log_analytics_workspace_id must not be null."
  }
}


locals {
  tlr_selected_realm = var.tlr_secret_expiry_alert != null ? var.tlr_secret_expiry_alert.realm : null

  tlr_selected_realm_config = local.tlr_selected_realm != null ? (
    try(
      [for cfg in var.tlr_secret_expiry_alert_config : cfg if cfg.realm == local.tlr_selected_realm][0],
      null
    )
  ) : null

  tlr_monitoring_enabled = local.tlr_selected_realm_config != null
}

variable "tlr_vpc_configs" {
  type = map(object({
    vpc_id = string
    subnets = list(object({
      cidr_block = string
      zone       = string
    }))
  }))
  default = {
    main = {
      vpc_id = "vpc-12345"
      subnets = [
        {
          cidr_block = "10.0.1.0/24"
          zone       = "us-east-1a"
        },
        {
          cidr_block = "10.0.2.0/24"
          zone       = "us-east-1b"
        }
      ]
    }
  }
}

locals {
  tlr_subnet_configs = {
    for vpc_key, vpc in var.tlr_vpc_configs : vpc_key => [
      for subnet in vpc.subnets : {
        vpc_id     = vpc.vpc_id
        cidr_block = subnet.cidr_block
        zone       = subnet.zone
      }
    ]
  }
}

resource "aws_subnet" "tlr_main" {
  for_each = {
    for subnet in flatten([
      for vpc_key, subnets in local.tlr_subnet_configs : [
        for subnet in subnets : {
          key    = "${vpc_key}-${subnet.zone}"
          config = subnet
        }
      ]
    ]) : subnet.key => subnet.config
  }

  vpc_id            = each.value.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.zone

  tags = {
    Name = each.key
  }
}