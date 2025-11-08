# Test: Count Variations Examples
# Prefix: cv_

# Input variables for testing different count scenarios
variable "cv_environment" {
  description = "Environment name for testing"
  type        = string
  default     = "dev"
}

variable "cv_instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 2
}

variable "cv_enable_extra_instances" {
  description = "Flag to enable additional instances"
  type        = bool
  default     = true
}

variable "cv_subnet_cidrs" {
  description = "List of subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "cv_tags" {
  description = "Tags to apply to resources"
  type        = list(string)
  default     = ["app", "web", "db"]
}

locals {
  cv_test2 = var.cv_instance_count
}

# Basic count example with null resources
resource "null_resource" "cv_basic_count" {
  count = var.cv_instance_count

  triggers = {
    instance_id = "instance-${count.index}"
    name        = "instance-${count.index + 1}-of-${var.cv_instance_count}"
    tag         = var.cv_tags[count.index]
  }
}

# Conditional count example
resource "null_resource" "cv_conditional_count" {
  count = var.cv_enable_extra_instances ? 2 : 0

  triggers = {
    instance_id = "extra-instance-${count.index}"
    enabled     = "true"
  }
}

# Count with length function
resource "null_resource" "cv_subnet_resources" {
  count = length(var.cv_subnet_cidrs)

  triggers = {
    subnet_cidr = var.cv_subnet_cidrs[count.index]
    subnet_name = "subnet-${count.index}"
  }
}

# Local value using count index
locals {
  cv_instance_names = [
    for idx in range(var.cv_instance_count) :
    "server-${var.cv_environment}-${idx + 1}"
  ]

  # Demonstrate count in dynamic block preparation
  cv_port_configs = [
    for port in [80, 443, 8080] :
    {
      port        = port
      protocol    = port == 443 ? "https" : "http"
      description = "Port ${port}"
    }
  ]

  cv_test = [for MyValue in null_resource.cv_basic_count : MyValue.triggers.instance_id]
}

# Resource with complex count logic
resource "null_resource" "cv_complex_count" {
  count = var.cv_environment == "prod" ? var.cv_instance_count * 2 : var.cv_instance_count

  triggers = {
    name        = local.cv_instance_names[count.index % var.cv_instance_count]
    environment = var.cv_environment
    is_prod     = var.cv_environment == "prod" ? "true" : "false"
  }
}

# Test resource with dynamic blocks using count
resource "null_resource" "cv_with_dynamic_blocks" {
  count = var.cv_instance_count

  triggers = {
    instance_name = "dynamic-instance-${count.index}"

  }

  lifecycle {
    precondition {
      condition     = contains([for cfg in local.cv_port_configs : cfg.port], 443)
      error_message = "HTTPS port (443) must be included in port configurations"
    }
  }
}

#Outputs for validation
output "cv_basic_count_ids" {
  value = [for testVal in null_resource.cv_basic_count : testVal.triggers.instance_id]
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
