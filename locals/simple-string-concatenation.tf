# Test: Simple String Concatenation
# Prefix: ssc_ (simple_string_concatenation)

variable "ssc_environment" {
  type    = string
  default = "dev"
}

variable "ssc_region" {
  type    = string
  default = "us-west-2"
}

variable "ssc_app_config" {
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

variable "ssc_instance_sizes" {
  type = map(string)
  default = {
    small  = "t3.micro"
    medium = "t3.small"
    large  = "t3.medium"
  }
}

locals {
  # Simple string concatenation
  ssc_app_name = "${var.ssc_app_config.name}-${var.ssc_environment}"

  # Basic map lookup with default
  ssc_instance_type = lookup(var.ssc_instance_sizes, var.ssc_environment == "prod" ? "large" : "small", "t3.micro")

  # Simple conditional
  ssc_is_production = var.ssc_environment == "prod"

  # Basic map transformation
  ssc_tags = {
    Name        = local.ssc_app_name
    Environment = var.ssc_environment
    Region      = var.ssc_region
    Managed_By  = "terraform"
  }

  # Simple list
  ssc_allowed_ports = concat(
    [var.ssc_app_config.port],
    var.ssc_app_config.enable_ssl ? [443] : []
  )
}

/*

# Given input values:
var.ssc_environment = "dev"
var.ssc_region = "us-west-2"
var.ssc_app_config = {
    name = "myapp"
    port = 8080
    enable_ssl = true
}

# Resolved locals:
local.ssc_app_name = "myapp-dev"
local.ssc_instance_type = "t3.micro"  # because environment is "dev", so it picks "small"
local.ssc_is_production = false
local.ssc_tags = {
    Name = "myapp-dev"
    Environment = "dev"
    Region = "us-west-2"
    Managed_By = "terraform"
}
local.ssc_allowed_ports = [8080, 443]  # includes 443 because enable_ssl is true

*/