# Test Case 1: Basic Variable References
variable "environment" {
  type    = string
  default = "development"
}

variable "instance_count" {
  type    = number
  default = 2
}

# Test Case 2: List and Map Variables
variable "availability_zones" {
  type    = list(string)
  default = ["us-west-1a", "us-west-1b"]
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Project     = "test"
  }
}

# Test Case 3: Complex Type Constraints
variable "server_config" {
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
  server_name = "server-${var.environment}"

  # Numeric operations
  total_storage = var.instance_count * var.server_config.volume_size

  # Conditional expression
  environment_tag = var.environment == "production" ? "prod" : "non-prod"

  # List operations
  first_az = var.availability_zones[0]
  az_count = length(var.availability_zones)

  # Map operations
  all_tags = merge(var.tags, {
    Name = local.server_name
  })

  # Complex expressions
  instance_tags = {
    for idx in range(var.instance_count) :
    "instance-${idx}" => merge(local.all_tags, {
      InstanceNumber = tostring(idx + 1)
    })
  }
}

# Test Case 5: Output Values
output "server_configuration" {
  value = {
    name          = local.server_name
    total_storage = local.total_storage
    environment   = local.environment_tag
    instances     = local.instance_tags
  }
}