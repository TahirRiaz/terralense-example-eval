# Input variables for testing different count scenarios
variable "environment" {
  description = "Environment name for testing"
  type        = string
  default     = "dev"
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 2
}

variable "enable_extra_instances" {
  description = "Flag to enable additional instances"
  type        = bool
  default     = true
}

variable "subnet_cidrs" {
  description = "List of subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = list(string)
  default     = ["app", "web", "db"]
}

locals {
  test2 = var.instance_count
}

# Basic count example with null resources
resource "null_resource" "basic_count" {
  count = var.instance_count

  triggers = {
    instance_id = "instance-${count.index}"
    name        = "instance-${count.index + 1}-of-${var.instance_count}"
    tag         = var.tags[count.index]
  }
}

# Conditional count example
resource "null_resource" "conditional_count" {
  count = var.enable_extra_instances ? 2 : 0

  triggers = {
    instance_id = "extra-instance-${count.index}"
    enabled     = "true"
  }
}

# Count with length function
resource "null_resource" "subnet_resources" {
  count = length(var.subnet_cidrs)

  triggers = {
    subnet_cidr = var.subnet_cidrs[count.index]
    subnet_name = "subnet-${count.index}"
  }
}

# Local value using count index
locals {
  instance_names = [
    for idx in range(var.instance_count) :
    "server-${var.environment}-${idx + 1}"
  ]

  # Demonstrate count in dynamic block preparation
  port_configs = [
    for port in [80, 443, 8080] :
    {
      port        = port
      protocol    = port == 443 ? "https" : "http"
      description = "Port ${port}"
    }
  ]

  test = [for MyValue in null_resource.basic_count : MyValue.triggers.instance_id]
}

# Resource with complex count logic
resource "null_resource" "complex_count" {
  count = var.environment == "prod" ? var.instance_count * 2 : var.instance_count

  triggers = {
    name        = local.instance_names[count.index % var.instance_count]
    environment = var.environment
    is_prod     = var.environment == "prod" ? "true" : "false"
  }
}

# Test resource with dynamic blocks using count
resource "null_resource" "with_dynamic_blocks" {
  count = var.instance_count

  triggers = {
    instance_name = "dynamic-instance-${count.index}"

  }

  lifecycle {
    precondition {
      condition     = contains([for cfg in local.port_configs : cfg.port], 443)
      error_message = "HTTPS port (443) must be included in port configurations"
    }
  }
}

#Outputs for validation
output "basic_count_ids" {
  value = [for testVal in null_resource.basic_count : testVal.triggers.instance_id]
}

# output "basic_count_names" {
#   value = {
#     for idx, NewTest in null_resource.basic_count : 
#     idx => NewTest.triggers.name
#   }
# }

# # output "conditional_resources" {
# #   value = null_resource.conditional_count[*].triggers
# # }

# # Should be changed to check if resources exist first
# output "conditional_resources" {
#   value = length(null_resource.conditional_count) > 0 ? [for r in null_resource.conditional_count : r.triggers] : []
# }

# output "subnet_details" {
#   value = [for resource in null_resource.subnet_resources : resource.triggers]
# }