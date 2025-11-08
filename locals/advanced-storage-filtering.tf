# Test: Advanced Storage Filtering
# Prefix: asf_ (advanced_storage_filtering)

variable "asf_environment" {
  type    = string
  default = "dev"
}

variable "asf_region" {
  type    = string
  default = "us-west-2"
}

variable "asf_app_config" {
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

variable "asf_instance_sizes" {
  type = map(string)
  default = {
    small  = "t3.micro"
    medium = "t3.small"
    large  = "t3.medium"
  }
}



locals {
  # Simple string concatenation
  asf_app_name = "${var.asf_app_config.name}-${var.asf_environment}"

  # Basic map lookup with default
  asf_instance_type = lookup(var.asf_instance_sizes, var.asf_environment == "prod" ? "large" : "small", "t3.micro")

  # Simple conditional
  asf_is_production = var.asf_environment == "prod"

  # Basic map transformation
  asf_tags = {
    Name        = local.asf_app_name
    Environment = var.asf_environment
    Region      = var.asf_region
    Managed_By  = "terraform"
  }

  # Simple list
  asf_allowed_ports = concat(
    [var.asf_app_config.port],
    var.asf_app_config.enable_ssl ? [443] : []
  )

  # For expression to transform instance sizes into a specific format
  asf_instance_configs = {
    for size, type in var.asf_instance_sizes :
    size => {
      name          = "${local.asf_app_name}-${size}"
      instance_type = type
      priority      = size == "small" ? "low" : size == "medium" ? "medium" : "high"
    }
  }

  asf_env_count = 2

  asf_env_names = [
    for i in range(local.asf_env_count) :
    "${local.asf_app_name}-${var.asf_environment}-${format("%02d", i + 1)}"
  ]

  # Advanced storage configuration with nested maps and dynamic settings
  asf_storage_config = {
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
  asf_filtered_sizes = [
    for size in data.azurerm_virtual_machine_sizes.asf_available.sizes : size
    if size.number_of_cores >= 2 &&
    size.memory_in_mb >= 4096 &&
    !startswith(size.name, "Standard_B")
  ]

  # Take only first 3 sizes that match our criteria
  asf_selected_sizes = slice(local.asf_filtered_sizes, 0, 3)

}

# Count Example - Creates multiple instances based on a count
resource "aws_instance" "asf_web" {
  count = local.asf_env_count

  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = local.asf_instance_type

  tags = merge(local.asf_tags, {
    Name = local.asf_env_names[count.index]
  })
}

# For Each Example - Creates resources based on a map or set
resource "aws_security_group_rule" "asf_app_ports" {
  for_each = toset(local.asf_allowed_ports)

  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.asf_main.id

  description = "Allow ${each.value} inbound"
}

# Dynamic Block Example - Creates nested blocks dynamically
resource "aws_security_group" "asf_main" {
  name        = local.asf_app_name
  description = "Security group for ${local.asf_app_name}"
  vpc_id      = aws_vpc.asf_main.id

  dynamic "ingress" {
    for_each = local.asf_storage_config[var.asf_environment].network_rules
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "HTTPS from ${ingress.value}"
    }
  }

  tags = local.asf_tags
}

# For Expression in Resource - Creates instances based on instance_configs
resource "aws_instance" "asf_servers" {
  for_each = local.asf_instance_configs

  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = each.value.instance_type

  tags = merge(local.asf_tags, {
    Name     = each.value.name
    Priority = each.value.priority
  })
}

# Data Block with Dynamic Query - Fetches available VM sizes
data "azurerm_virtual_machine_sizes" "asf_available" {
  location = var.asf_region
}

# Using For Expression with Data Source Results
resource "azurerm_virtual_machine" "asf_vm_cluster" {
  for_each = {
    for idx, size in local.asf_selected_sizes :
    "${local.asf_app_name}-vm-${idx}" => size
  }

  name                  = each.key
  location              = azurerm_resource_groupx.asf_main.location
  resource_group_name   = azurerm_resource_group.asf_main.name
  vm_size               = each.value.name
  network_interface_ids = [azurerm_network_interface.asf_main[each.key].id]

  dynamic "storage_data_disk" {
    for_each = local.asf_storage_config[var.asf_environment].containers
    content {
      name              = "${each.key}-${storage_data_disk.value}"
      create_option     = "Empty"
      disk_size_gb      = 10
      lun               = storage_data_disk.key
      managed_disk_type = local.asf_storage_config[var.asf_environment].tier == "Premium" ? "Premium_LRS" : "Standard_LRS"
    }
  }

  tags = local.asf_tags
}


