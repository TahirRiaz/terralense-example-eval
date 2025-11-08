# providers.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "us-east-1"
}

# variables.tf
variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, prod, staging)"
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod", "staging"], var.environment)
    error_message = "Environment must be one of: dev, prod, staging"
  }
}

variable "aws_regions" {
  type = map(object({
    name = string
    azs  = list(string)
  }))
  description = "Map of AWS regions and their availability zones"
  default = {
    us_east_1 = {
      name = "us-east-1"
      azs  = ["us-east-1a", "us-east-1b"]
    }
    us_west_2 = {
      name = "us-west-2"
      azs  = ["us-west-2a", "us-west-2b"]
    }
  }
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block"
  }
}

variable "subnet_cidrs" {
  type        = map(string)
  description = "Map of subnet names to CIDR blocks"
  default = {
    subnet_1 = "10.0.1.0/24"
    subnet_2 = "10.0.2.0/24"
    subnet_3 = "10.0.3.0/24"
  }

  validation {
    condition     = alltrue([for cidr in values(var.subnet_cidrs) : can(cidrhost(cidr, 0))])
    error_message = "All subnet CIDRs must be valid IPv4 CIDR blocks"
  }
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default = {
    Terraform = "true"
  }
}

# locals.tf
locals {
  # Common tags merged with environment-specific tags
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )

  # Organize AZs by region
  region_azs = {
    for region_key, region in var.aws_regions : region_key => {
      name = region.name
      azs  = region.azs
    }
  }

  # IAM policy statements for dynamic block example
  iam_policy_statements = [
    {
      sid       = "ListBucketAccess"
      actions   = ["s3:ListBucket"]
      resources = ["arn:aws:s3:::example-bucket"]
      effect    = "Allow"
    },
    {
      sid       = "ObjectAccess"
      actions   = ["s3:GetObject", "s3:PutObject"]
      resources = ["arn:aws:s3:::example-bucket/*"]
      effect    = "Allow"
    }
  ]
}

# main.tf
# Data source for Availability Zones
data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "region-name"
    values = [var.aws_regions.us_east_1.name]
  }
}

# VPC data source
data "aws_vpc" "selected" {
  filter {
    name   = "cidr-block"
    values = [var.vpc_cidr]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Subnet data source using for_each
data "aws_subnet" "selected" {
  for_each = var.subnet_cidrs

  vpc_id = data.aws_vpc.selected.id

  filter {
    name   = "cidr-block"
    values = [each.value]
  }

  filter {
    name   = "availability-zone"
    values = [data.aws_availability_zones.available.names[index(keys(var.subnet_cidrs), each.key) % length(data.aws_availability_zones.available.names)]]
  }
}

# Example using dynamic blocks with IAM policy
data "aws_iam_policy_document" "example" {
  dynamic "statement" {
    for_each = local.iam_policy_statements
    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

# outputs.tf
output "availability_zones" {
  description = "List of available AZs"
  value       = data.aws_availability_zones.available.names
}

output "vpc_details" {
  description = "VPC details"
  value = {
    id         = data.aws_vpc.selected.id
    cidr_block = data.aws_vpc.selected.cidr_block
  }
}

output "subnet_details" {
  description = "Subnet details"
  value = {
    for k, subnet in data.aws_subnet.selected : k => {
      id                = subnet.id
      cidr_block        = subnet.cidr_block
      availability_zone = subnet.availability_zone
    }
  }
}

output "iam_policy" {
  description = "Generated IAM policy document"
  value       = data.aws_iam_policy_document.example.json
}