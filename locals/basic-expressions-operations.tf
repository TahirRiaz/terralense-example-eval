# Test: Basic Expressions Operations
# Prefix: beo_ (basic_expressions_operations)

# Test Case 1: Basic Variable References
variable "beo_environment" {
  type    = string
  default = "development"
}

variable "beo_instance_count" {
  type    = number
  default = 2
}

# Test Case 2: List and Map Variables
variable "beo_availability_zones" {
  type    = list(string)
  default = ["us-west-1a", "us-west-1b"]
}

variable "beo_tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Project     = "test"
  }
}

# Test Case 3: Complex Type Constraints
variable "beo_server_config" {
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
  beo_server_name = "server-${var.beo_environment}"

  # Numeric operations
  beo_total_storage = var.beo_instance_count * var.beo_server_config.volume_size

  # Conditional expression
  beo_environment_tag = var.beo_environment == "production" ? "prod" : "non-prod"

  # List operations
  beo_first_az = var.beo_availability_zones[0]
  beo_az_count = length(var.beo_availability_zones)

  # Map operations
  beo_all_tags = merge(var.beo_tags, {
    Name = local.beo_server_name
  })

  # Complex expressions
  beo_instance_tags = {
    for idx in range(var.beo_instance_count) :
    "instance-${idx}" => merge(local.beo_all_tags, {
      InstanceNumber = tostring(idx + 1)
    })
  }
}

# Test Case 5: Output Values
output "beo_server_configuration" {
  value = {
    name          = local.beo_server_name
    total_storage = local.beo_total_storage
    environment   = local.beo_environment_tag
    instances     = local.beo_instance_tags
  }
}