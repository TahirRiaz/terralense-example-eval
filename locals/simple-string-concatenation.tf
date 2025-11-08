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
}

/*

# Given input values:
var.environment = "dev"
var.region = "us-west-2"
var.app_config = {
    name = "myapp"
    port = 8080
    enable_ssl = true
}

# Resolved locals:
local.app_name = "myapp-dev"
local.instance_type = "t3.micro"  # because environment is "dev", so it picks "small"
local.is_production = false
local.tags = {
    Name = "myapp-dev"
    Environment = "dev"
    Region = "us-west-2"
    Managed_By = "terraform"
}
local.allowed_ports = [8080, 443]  # includes 443 because enable_ssl is true

*/