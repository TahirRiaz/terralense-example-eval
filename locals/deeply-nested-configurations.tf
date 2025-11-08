# Test: Deeply Nested Configurations
# Prefix: dnc_ (deeply_nested_configurations)

variable "dnc_environment" {
  type    = string
  default = "dev"
}

variable "dnc_region" {
  type    = string
  default = "us-west-2"
}

variable "dnc_app_config" {
  type = object({
    name       = string
    port       = number
    enable_ssl = bool
  })
  default = {
    name       = "myapp"
    port       = 8080
    enable_ssl = true
  }
}

variable "dnc_instance_sizes" {
  type = map(string)
  default = {
    small  = "t3.micro"
    medium = "t3.small"
    large  = "t3.medium"
  }
}




locals {
  # Simple string concatenation
  dnc_app_name = "${var.dnc_app_config.name}-${var.dnc_environment}"

  # Basic map lookup with default
  dnc_instance_type = lookup(var.dnc_instance_sizes, var.dnc_environment == "prod" ? "large" : "small", "t3.micro")

  # Simple conditional
  dnc_is_production = var.dnc_environment == "prod"

  # Basic map transformation
  dnc_tags = {
    Name        = local.dnc_app_name
    Environment = var.dnc_environment
    Region      = var.dnc_region
    Managed_By  = "terraform"
  }

  # Simple list
  dnc_allowed_ports = concat(
    [var.dnc_app_config.port],
    var.dnc_app_config.enable_ssl ? [443] : []
  )

  # For expression to transform instance sizes into a specific format
  dnc_instance_configs = {
    for size, type in var.dnc_instance_sizes :
    size => {
      name          = "${local.dnc_app_name}-${size}"
      instance_type = type
      priority      = size == "small" ? "low" : size == "medium" ? "medium" : "high"
    }
  }

  dnc_env_count = 2

  dnc_env_names = [
    for i in range(local.dnc_env_count) :
    "${local.dnc_app_name}-${var.dnc_environment}-${format("%02d", i + 1)}"
  ]


  # Advanced storage configuration with nested maps and dynamic settings
  dnc_storage_config = {
    for env in ["dev", "staging", "prod"] : env => {
      tier          = env == "prod" ? "Standard" : "Premium"
      replication   = env == "prod" ? "GRS" : "LRS"
      min_tls       = env == "prod" ? "TLS1_2" : "TLS1_1"
      network_rules = env == "prod" ? ["10.0.0.0/24", "10.0.1.0/24"] : ["10.0.0.0/16"]
      containers    = env == "prod" ? ["logs", "data", "backup"] : ["logs", "data"]
      lifecycle_rules = {
        logs = {
          days_to_cool_tier = env == "prod" ? 30 : 15
          days_to_delete    = env == "prod" ? 90 : 45
        }
        data = {
          days_to_cool_tier = env == "prod" ? 60 : 30
          days_to_delete    = env == "prod" ? 180 : 90
        }
      }
    }
  }

  # Filter VM sizes based on criteria and create a list
  dnc_filtered_sizes = [
    for size in data.azurerm_virtual_machine_sizes.dnc_available.sizes : size
    if size.number_of_cores >= 2 &&
    size.memory_in_mb >= 4096 &&
    !startswith(size.name, "Standard_B")
  ]

  # Take only first 3 sizes that match our criteria
  dnc_selected_sizes = slice(local.dnc_filtered_sizes, 0, 3)

}

data "azurerm_virtual_machine_sizes" "dnc_available" {
  location = var.dnc_region
  sizes    = [1, 2, 3]
}

data "azurerm_key_vault" "dnc_existing" {
  name                = "existing-key-vault-${var.dnc_environment}"
  resource_group_name = "security-${var.dnc_environment}"
  id                  = "simulated value"
  timeouts {
    read = "30m"
  }
}

data "azurerm_key_vault_secrets" "dnc_app_secrets" {
  key_vault_id = data.azurerm_key_vault.dnc_existing.id

  filter {
    name_prefix            = "APP_"
    enabled                = true
    expiration_date_before = timeadd(timestamp(), "8760h") # 1 year from now
  }
}


resource "azurerm_resource_group" "dnc_nested_instances" {
  for_each = var.dnc_instance_sizes
  name     = "${local.dnc_app_name}-${each.key}"
  location = var.dnc_region

  tags = {
    Instance_Size = each.value
    Instance_Tier = each.key
  }

  depends_on = [azurerm_resource_group.dnc_main]
}



resource "azurerm_resource_group" "dnc_main" {
  name     = local.dnc_app_name
  location = var.dnc_region
  tags     = local.dnc_tags
}


resource "azurerm_container_group" "dnc_app_instances" {
  count               = local.dnc_env_count
  name                = local.dnc_env_names[count.index]
  location            = var.dnc_region
  resource_group_name = azurerm_resource_group.dnc_main.name
  ip_address_type     = "Public"
  dns_name_label      = local.dnc_env_names[count.index]
  os_type             = "Linux"

  container {
    name   = "app"
    image  = "nginx:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = var.dnc_app_config.port
      protocol = "TCP"
    }
  }

  tags = merge(local.dnc_tags, {
    Instance_Number = count.index + 1
    Instance_Name   = local.dnc_env_names[count.index]
    # For expression to list all sibling instances
    Siblings = jsonencode([
      for name in local.dnc_env_names :
      name if name != local.dnc_env_names[count.index]
    ])
  })
}



resource "azurerm_storage_account" "dnc_advanced" {
  name                     = "${replace(lower(local.dnc_app_name), "-", "")}${var.dnc_environment}sa"
  resource_group_name      = azurerm_resource_group.dnc_main.name
  location                 = var.dnc_region
  account_tier             = lookup(local.dnc_storage_config[var.dnc_environment], "tier", "Standard")
  account_replication_type = lookup(local.dnc_storage_config[var.dnc_environment], "replication", "LRS")
  min_tls_version          = lookup(local.dnc_storage_config[var.dnc_environment], "min_tls", "TLS1_2")

  network_rules {
    default_action = "Deny"
    ip_rules       = local.dnc_storage_config[var.dnc_environment].network_rules
    bypass         = ["Metrics", "Logging"]
  }

  # Dynamic block for containers
  dynamic "blob_properties" {
    for_each = local.dnc_storage_config[var.dnc_environment].containers
    content {
      container_delete_retention_policy {
        days = var.dnc_environment == "prod" ? 14 : 7
      }
      delete_retention_policy {
        days = var.dnc_environment == "prod" ? 30 : 14
      }
    }
  }

  lifecycle_rule {
    enabled = true
    filters {
      prefix_match = ["logs/"]
    }
    actions {
      base_blob {
        tier_to_cool_after_days = local.dnc_storage_config[var.dnc_environment].lifecycle_rules.logs.days_to_cool_tier
        delete_after_days       = local.dnc_storage_config[var.dnc_environment].lifecycle_rules.logs.days_to_delete
      }
    }
  }

  lifecycle_rule {
    enabled = true
    filters {
      prefix_match = ["data/"]
    }
    actions {
      base_blob {
        tier_to_cool_after_days = local.dnc_storage_config[var.dnc_environment].lifecycle_rules.data.days_to_cool_tier
        delete_after_days       = local.dnc_storage_config[var.dnc_environment].lifecycle_rules.data.days_to_delete
      }
    }
  }

  tags = merge(local.dnc_tags, {
    StorageType    = local.dnc_storage_config[var.dnc_environment].tier
    Replication    = local.dnc_storage_config[var.dnc_environment].replication
    ContainerCount = length(local.dnc_storage_config[var.dnc_environment].containers)
    SecurityLevel  = var.dnc_environment == "prod" ? "High" : "Standard"
  })

}
