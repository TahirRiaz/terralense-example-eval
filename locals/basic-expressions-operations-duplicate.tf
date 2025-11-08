# Test: Basic Expressions Operations Duplicate
# Prefix: beod_ (basic_expressions_operations_dup)

# Test Case 1: Basic Variable References
variable "beod_environment" {
  type    = string
  default = "development"
}

variable "beod_instance_count" {
  type    = number
  default = 2
}

# Test Case 2: List and Map Variables
variable "beod_availability_zones" {
  type    = list(string)
  default = ["us-west-1a", "us-west-1b"]
}

variable "beod_tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Project     = "test"
  }
}

# Test Case 3: Complex Type Constraints
variable "beod_server_config" {
  type = object({
    instance_type = string
    ami_id        = string
    volume_size   = number
    tags          = map(string)
  })
  default = {
    instance_type = "t2.micro"
    ami_id        = "ami-12345678"
    volume_size   = 20
    tags = {
      Name = "test-server"
    }
  }
}

# Test Case 4: Expression Evaluation
locals {
  # String interpolation
  beod_server_name = "server-${var.beod_environment}"

  # Numeric operations
  beod_total_storage = var.beod_instance_count * var.beod_server_config.volume_size

  # Conditional expression
  beod_environment_tag = var.beod_environment == "production" ? "prod" : "non-prod"

  # List operations
  beod_first_az = var.beod_availability_zones[0]
  beod_az_count = length(var.beod_availability_zones)

  # Map operations
  beod_all_tags = merge(var.beod_tags, {
    Name = local.beod_server_name
  })

  # Complex expressions
  beod_instance_tags = {
    for idx in range(var.beod_instance_count) :
    "instance-${idx}" => merge(local.beod_all_tags, {
      InstanceNumber = tostring(idx + 1)
    })
  }
}

# Test Case 5: Output Values
output "beod_server_configuration" {
  value = {
    name          = local.beod_server_name
    total_storage = local.beod_total_storage
    environment   = local.beod_environment_tag
    instances     = local.beod_instance_tags
  }
}