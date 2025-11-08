variable "environment" {
  type    = string
  default = "dev"
}

variable "region" {
  type    = string
  default = "us-west-2"
}

variable "app_config" {
  type = object({
    name        = string
    port        = number
    enable_ssl  = bool
  })
  default = {
    name        = "myapp"
    port        = 8080
    enable_ssl  = true
  }
}

variable "instance_sizes" {
  type = map(string)
  default = {
    small  = "t3.micro"
    medium = "t3.small"
    large  = "t3.medium"
  }
}




locals {
  # Simple string concatenation
  app_name = "${var.app_config.name}-${var.environment}"
  
  # Basic map lookup with default
  instance_type = lookup(var.instance_sizes, var.environment == "prod" ? "large" : "small", "t3.micro")
  
  # Simple conditional
  is_production = var.environment == "prod"
  
  # Basic map transformation
  tags = {
    Name        = local.app_name
    Environment = var.environment
    Region      = var.region
    Managed_By  = "terraform"
  }
  
  # Simple list
  allowed_ports = concat(
    [var.app_config.port],
    var.app_config.enable_ssl ? [443] : []
  )

  # For expression to transform instance sizes into a specific format
  instance_configs = {
    for size, type in var.instance_sizes :
    size => {
      name          = "${local.app_name}-${size}"
      instance_type = type
      priority      = size == "small" ? "low" : size == "medium" ? "medium" : "high"
    }
  }

env_count = 2
  
  env_names = [
    for i in range(local.env_count) : 
    "${local.app_name}-${var.environment}-${format("%02d", i + 1)}"
  ]


  # Advanced storage configuration with nested maps and dynamic settings
  storage_config = {
    for env in ["dev", "staging", "prod"] : env => {
      tier          = env == "prod" ? "Standard" : "Premium"
      replication   = env == "prod" ? "GRS" : "LRS"
      min_tls      = env == "prod" ? "TLS1_2" : "TLS1_1"
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
  filtered_sizes = [
    for size in data.azurerm_virtual_machine_sizes.available.sizes : size
    if size.number_of_cores >= 2 &&
       size.memory_in_mb >= 4096 &&
       !startswith(size.name, "Standard_B")
  ]
  
  # Take only first 3 sizes that match our criteria
  selected_sizes = slice(local.filtered_sizes, 0, 3)

}

data "azurerm_virtual_machine_sizes" "available" {
  location = var.region
  sizes = [1,2,3]
}

data "azurerm_key_vault" "existing" {
  name                = "existing-key-vault-${var.environment}"
  resource_group_name = "security-${var.environment}"
  id = "simulated value"
  timeouts {
    read = "30m"
  }
}

data "azurerm_key_vault_secrets" "app_secrets" {
  key_vault_id = data.azurerm_key_vault.existing.id

  filter {
    name_prefix = "APP_"
    enabled     = true
    expiration_date_before = timeadd(timestamp(), "8760h")  # 1 year from now
  }
}


resource "azurerm_resource_group" "nested_instances" {
  for_each = var.instance_sizes
  name     = "${local.app_name}-${each.key}"
  location = var.region
  
  tags = {
    Instance_Size = each.value
    Instance_Tier = each.key
  }
  
  depends_on = [azurerm_resource_group.main]
}



resource "azurerm_resource_group" "main" {
  name     = local.app_name
  location = var.region
  tags = local.tags
}


resource "azurerm_container_group" "app_instances" {
  count               = local.env_count
  name                = local.env_names[count.index]
  location            = var.region
  resource_group_name = azurerm_resource_group.main.name
  ip_address_type     = "Public"
  dns_name_label      = local.env_names[count.index]
  os_type             = "Linux"

  container {
    name   = "app"
    image  = "nginx:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = var.app_config.port
      protocol = "TCP"
    }
  }

  tags = merge(local.tags, {
    Instance_Number = count.index + 1
    Instance_Name   = local.env_names[count.index]
    # For expression to list all sibling instances
    Siblings = jsonencode([
      for name in local.env_names : 
      name if name != local.env_names[count.index]
    ])
  })
}



resource "azurerm_storage_account" "advanced" {
  name                     = "${replace(lower(local.app_name), "-", "")}${var.environment}sa"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.region
  account_tier             = lookup(local.storage_config[var.environment], "tier", "Standard")
  account_replication_type = lookup(local.storage_config[var.environment], "replication", "LRS")
  min_tls_version         = lookup(local.storage_config[var.environment], "min_tls", "TLS1_2")

  network_rules {
    default_action = "Deny"
    ip_rules       = local.storage_config[var.environment].network_rules
    bypass         = ["Metrics", "Logging"]
  }

  # Dynamic block for containers
  dynamic "blob_properties" {
    for_each = local.storage_config[var.environment].containers
    content {
      container_delete_retention_policy {
        days = var.environment == "prod" ? 14 : 7
      }
      delete_retention_policy {
        days = var.environment == "prod" ? 30 : 14
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
        tier_to_cool_after_days    = local.storage_config[var.environment].lifecycle_rules.logs.days_to_cool_tier
        delete_after_days          = local.storage_config[var.environment].lifecycle_rules.logs.days_to_delete
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
        tier_to_cool_after_days    = local.storage_config[var.environment].lifecycle_rules.data.days_to_cool_tier
        delete_after_days          = local.storage_config[var.environment].lifecycle_rules.data.days_to_delete
      }
    }
  }

  tags = merge(local.tags, {
    StorageType    = local.storage_config[var.environment].tier
    Replication    = local.storage_config[var.environment].replication
    ContainerCount = length(local.storage_config[var.environment].containers)
    SecurityLevel  = var.environment == "prod" ? "High" : "Standard"
  })

}
