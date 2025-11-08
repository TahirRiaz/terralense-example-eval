terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.default_tags
  }
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for all resources"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must be valid (e.g., us-east-1, eu-west-1)."
  }
}

variable "default_tags" {
  type        = map(string)
  default     = {}
  description = "Default tags for all resources"
}

variable "vpc_configs" {
  type = map(object({
    vpc_id               = string
    cidr_block           = string
    enable_dns_hostnames = optional(bool, true)
    enable_dns_support   = optional(bool, true)
    subnets = list(object({
      cidr_block = string
      zone       = string
      type       = string
      tags       = optional(map(string), {})
      route_table_routes = optional(list(object({
        destination_cidr_block = string
        gateway_id             = optional(string)
        nat_gateway_id         = optional(string)
      })), [])
    }))
    nat_gateways = optional(map(object({
      subnet_key        = string
      eip_allocation_id = optional(string)
    })), {})
  }))



  default = {
    main = {
      vpc_id               = "vpc-12345"
      cidr_block           = "10.0.0.0/16"
      enable_dns_hostnames = "each.value.enable_dns_hostnames"
      enable_dns_support   = "each.value.enable_dns_support"
      subnets = [
        {
          cidr_block = "10.0.1.0/24"
          zone       = "us-east-1a"
          type       = "public"
          tags = {
            Environment = "dev"
            Owner       = "platform-team"
            Project     = "infrastructure"
          }
          route_table_routes = [
            {
              destination_cidr_block = "0.0.0.0/0"
              gateway_id             = "igw-12345"
            }
          ]
        },
        {
          cidr_block = "10.0.2.0/24"
          zone       = "us-east-1b"
          type       = "private"
          tags = {
            Environment = "dev"
            Owner       = "platform-team"
            Project     = "infrastructure"
          }
          route_table_routes = [
            {
              destination_cidr_block = "0.0.0.0/0"
              nat_gateway_id         = "nat-12345"
            }
          ]
        }
      ]
      nat_gateways = {
        main = {
          subnet_key = "public-us-east-1a"
        }
      }
    }
  }

  validation {
    condition = length([
      for vpc_key, vpc in var.vpc_configs :
      vpc if !can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", vpc.cidr_block)) ||
      !can(tonumber(split("/", vpc.cidr_block)[1]) >= 16 && tonumber(split("/", vpc.cidr_block)[1]) <= 28)
    ]) == 0
    error_message = "All VPC CIDR blocks must be valid IPv4 CIDR notation with subnet mask between /16 and /28."
  }

  validation {
    condition = length(flatten([
      for vpc_key, vpc in var.vpc_configs : [
        for subnet in vpc.subnets :
        subnet if !contains(["public", "private"], subnet.type)
      ]
    ])) == 0
    error_message = "Subnet type must be either 'public' or 'private'."
  }
}

locals {
  subnet_configs = {
    for pair in flatten([
      for vpc_key, vpc in var.vpc_configs : [
        for subnet in vpc.subnets : {
          key = "${vpc_key}-${subnet.type}-${subnet.zone}"
          value = merge(subnet, {
            vpc_id  = vpc.vpc_id
            vpc_key = vpc_key
          })
        }
      ]
    ]) : pair.key => pair.value
  }

  // Group subnets by type for route table association
  subnet_by_type = {
    for vpc_key, vpc in var.vpc_configs : vpc_key => {
      public = [
        for subnet_key, subnet in local.subnet_configs : subnet_key
        if subnet.vpc_key == vpc_key && subnet.type == "public"
      ]
      private = [
        for subnet_key, subnet in local.subnet_configs : subnet_key
        if subnet.vpc_key == vpc_key && subnet.type == "private"
      ]
    }
  }

  // NAT Gateway configurations
  nat_gateway_configs = {
    for pair in flatten([
      for vpc_key, vpc in var.vpc_configs : [
        for nat_key, nat in vpc.nat_gateways : {
          key = "${vpc_key}-${nat_key}"
          value = merge(nat, {
            vpc_id  = vpc.vpc_id
            vpc_key = vpc_key
          })
        }
      ]
    ]) : pair.key => pair.value
  }

}




resource "aws_vpc" "main" {
  for_each = var.vpc_configs

  cidr_block           = each.value.cidr_block
  enable_dns_hostnames = each.value.enable_dns_hostnames
  enable_dns_support   = each.value.enable_dns_support

  tags = {
    Name = each.key
  }
}


resource "aws_subnet" "main" {
  for_each = local.subnet_configs

  vpc_id            = each.value.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.zone

  tags = merge(
    {
      Name = each.key
      Type = each.value.type
    },
    each.value.tags
  )

  lifecycle {
    precondition {
      condition     = each.value.zone != null
      error_message = "Availability zone must be specified for subnet ${each.key}."
    }
  }
}

resource "aws_route_table" "public" {
  for_each = {
    for vpc_key, vpc in var.vpc_configs : vpc_key => vpc
    if length(local.subnet_by_type[vpc_key].public) > 0
  }

  vpc_id = each.value.vpc_id

  dynamic "route" {
    for_each = distinct(flatten([
      for subnet_key in local.subnet_by_type[each.key].public : local.subnet_configs[subnet_key].route_table_routes
    ]))

    content {
      cidr_block     = route.value.destination_cidr_block
      gateway_id     = route.value.gateway_id
      nat_gateway_id = route.value.nat_gateway_id
    }
  }


  tags = {
    Name = "${each.key}-public"
  }
}

resource "aws_route_table" "private" {
  for_each = {
    for vpc_key, vpc in var.vpc_configs : vpc_key => vpc
    if length(local.subnet_by_type[vpc_key].private) > 0
  }

  vpc_id = each.value.vpc_id

  dynamic "route" {
    for_each = distinct(flatten([
      for subnet_key in local.subnet_by_type[each.key].private : local.subnet_configs[subnet_key].route_table_routes
    ]))

    content {
      cidr_block     = route.value.destination_cidr_block
      gateway_id     = route.value.gateway_id
      nat_gateway_id = route.value.nat_gateway_id
    }
  }

  tags = {
    Name = "${each.key}-private"
  }
}

resource "aws_route_table_association" "public" {
  for_each = {
    for vpc_key, subnets in local.subnet_by_type : vpc_key => subnets.public
    if length(subnets.public) > 0
  }

  subnet_id      = aws_subnet.main[each.value].id
  route_table_id = aws_route_table.public[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each = {
    for vpc_key, subnets in local.subnet_by_type : vpc_key => subnets.private
    if length(subnets.private) > 0
  }

  subnet_id      = aws_subnet.main[each.value].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_eip" "nat" {
  for_each = local.nat_gateway_configs

  vpc = true

  tags = {
    Name = "${each.key}-nat"
  }
}

resource "aws_nat_gateway" "main" {
  for_each = local.nat_gateway_configs

  allocation_id = coalesce(
    each.value.eip_allocation_id,
    aws_eip.nat[each.key].id
  )
  subnet_id = aws_subnet.main["${each.value.vpc_key}-${each.value.subnet_key}"].id

  tags = {
    Name = each.key
  }
}

output "vpc_ids" {
  description = "Map of VPC IDs"
  value = {
    for vpc_key, vpc in aws_vpc.main : vpc_key => vpc.id
  }
}

output "subnet_ids" {
  description = "Map of subnet IDs"
  value = {
    for subnet_key, subnet in aws_subnet.main : subnet_key => subnet.id
  }
}

output "nat_gateway_ids" {
  description = "Map of NAT Gateway IDs"
  value = {
    for nat_key, nat in aws_nat_gateway.main : nat_key => nat.id
  }
}

output "route_table_ids" {
  description = "Map of route table IDs"
  value = {
    public = {
      for rt_key, rt in aws_route_table.public : rt_key => rt.id
    }
    private = {
      for rt_key, rt in aws_route_table.private : rt_key => rt.id
    }
  }
}