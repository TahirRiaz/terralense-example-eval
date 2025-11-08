# Test: Complex VPC Preconditions
# Prefix: cvp_ (complex_vpc_preconditions)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Complex variable definitions with validation
variable "cvp_environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  default     = "dev"
  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.cvp_environment))
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "cvp_vpc_cidr_blocks" {
  type = map(object({
    primary   = string
    secondary = list(string)
    tags      = map(string)
  }))
  description = "Map of VPC CIDR blocks with their configurations"
  default = {
    main = {
      primary   = "10.0.0.0/16"
      secondary = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      tags = {
        Purpose = "Main VPC"
        Team    = "Infrastructure"
      }
    }
    secondary = {
      primary   = "172.16.0.0/16"
      secondary = ["172.16.1.0/24", "172.16.2.0/24"]
      tags = {
        Purpose = "Secondary VPC"
        Team    = "Development"
      }
    }
  }
}

variable "cvp_instance_types" {
  type = list(object({
    size  = string
    specs = map(number)
  }))
  default = [
    {
      size = "t3.micro"
      specs = {
        cpu    = 2
        memory = 1
      }
    }
  ]
}

# Complex locals with various expressions
locals {
  cvp_common_tags = {
    Environment = var.cvp_environment
    Project     = "TerraformTest"
    ManagedBy   = "Terraform"
  }

  # Complex map transformation
  cvp_vpc_configs = {
    for k, v in var.cvp_vpc_cidr_blocks : k => {
      primary_cidr = v.primary
      subnet_configs = [
        for idx, cidr in v.secondary : {
          cidr_block = cidr
          zone       = data.aws_availability_zones.cvp_available.names[idx % length(data.aws_availability_zones.cvp_available.names)]
          tags = merge(v.tags, local.cvp_common_tags, {
            Name = format("subnet-%s-%02d", k, idx + 1)
          })
        }
      ]
    }
  }

  # Nested dynamic expressions
  cvp_instance_map = {
    for idx, type in var.cvp_instance_types : type.size => {
      index         = idx
      compute_units = type.specs.cpu * 2
      memory_ratio  = type.specs.memory / type.specs.cpu
      tags = merge(local.cvp_common_tags, {
        InstanceType = type.size
        ComputeUnits = format("%.1f", type.specs.cpu * 2)
      })
    }
  }

  # Complex conditional expressions
  cvp_environment_configs = {
    is_production = var.cvp_environment == "prod"
    backup_retention = (
      var.cvp_environment == "prod" ? 30 :
      var.cvp_environment == "staging" ? 7 :
      1
    )
    alert_threshold = coalesce(try(var.cvp_instance_types[0].specs.memory * 0.8, null), 0.5)
  }
}

# VPC Resource with complex configurations
resource "aws_vpc" "cvp_main" {
  for_each = var.cvp_vpc_cidr_blocks

  cidr_block           = each.value.primary
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.cvp_common_tags,
    each.value.tags,
    {
      Name = format("vpc-%s-%s", var.cvp_environment, each.key)
      Tier = local.cvp_environment_configs.is_production ? "production" : "standard"
    }
  )
}

# Subnet resources using the complex VPC configurations
resource "aws_subnet" "cvp_main" {
  for_each = {
    for subnet in flatten([
      for vpc_key, vpc in local.cvp_vpc_configs : [
        for subnet_config in vpc.subnet_configs : {
          vpc_key    = vpc_key
          vpc_id     = aws_vpc.cvp_main[vpc_key].id
          cidr_block = subnet_config.cidr_block
          zone       = subnet_config.zone
          tags       = subnet_config.tags
        }
      ]
    ]) : "${subnet.vpc_key}-${subnet.zone}" => subnet
  }

  vpc_id            = each.value.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.zone

  tags = merge(
    each.value.tags,
    {
      SubnetKey = each.key
    }
  )

  lifecycle {
    precondition {
      condition     = cidrsubnet(aws_vpc.cvp_main[each.value.vpc_key].cidr_block, 8, 0) == each.value.cidr_block
      error_message = "Subnet CIDR must be a valid subdivision of the VPC CIDR."
    }
  }
}

# Data source for availability zones
data "aws_availability_zones" "cvp_available" {
  state = "available"
  names = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# Resource with complex dynamic blocks
resource "aws_security_group" "cvp_complex" {
  name_prefix = "complex-sg-${var.cvp_environment}"
  vpc_id      = aws_vpc.cvp_main["main"].id

  dynamic "ingress" {
    for_each = {
      http  = 80
      https = 443
      ssh   = 22
    }

    content {
      description = "Allow ${ingress.key} traffic"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [
        for config in local.cvp_vpc_configs : config.primary_cidr
        if contains(keys(config), "primary_cidr")
      ]
    }
  }

  # Complex nested dynamic blocks
  dynamic "egress" {
    for_each = local.cvp_vpc_configs

    content {
      from_port = 0
      to_port   = 0
      protocol  = "-1"

      dynamic "cidr_blocks" {
        for_each = egress.value.subnet_configs
        content {
          cidr_blocks = [cidr_blocks.value.cidr_block]
          description = "Access to ${cidr_blocks.value.zone}"
        }
      }
    }
  }

  tags = merge(
    local.cvp_common_tags,
    {
      Name          = format("complex-sg-%s", var.cvp_environment)
      SecurityLevel = local.cvp_environment_configs.is_production ? "high" : "standard"
    },
    {
      for k, v in local.cvp_instance_map : "Instance_${k}" => tostring(v.compute_units)
    }
  )

  lifecycle {
    create_before_destroy = true
    precondition {
      condition     = length(local.cvp_vpc_configs) > 0
      error_message = "At least one VPC configuration must be provided."
    }
  }
}

# Output with complex expressions
output "cvp_security_group_summary" {
  value = {
    id = aws_security_group.cvp_complex.id
    ingress_rules = {
      for rule in aws_security_group.cvp_complex.ingress : rule.description => {
        port        = rule.from_port
        cidr_blocks = rule.cidr_blocks
      }
    }
    config_summary = {
      vpc_count        = length(local.cvp_vpc_configs)
      instance_types   = keys(local.cvp_instance_map)
      total_subnets    = sum([for vpc in local.cvp_vpc_configs : length(vpc.subnet_configs)])
      environment_tier = local.cvp_environment_configs.is_production ? "production" : "non-production"
    }
  }
}