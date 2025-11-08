terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

variable "vpc_configs" {
  type = map(object({
    vpc_id = string
    subnets = list(object({
      cidr_block = string
      zone       = string
    }))
  }))
  default = {
    main = {
      vpc_id = "vpc-12345"
      subnets = [
        {
          cidr_block = "10.0.1.0/24"
          zone       = "us-east-1a"
        },
        {
          cidr_block = "10.0.2.0/24"
          zone       = "us-east-1b"
        }
      ]
    }
  }
}

locals {
  subnet_configs = {
    for vpc_key, vpc in var.vpc_configs : vpc_key => [
      for subnet in vpc.subnets : {
        vpc_id     = vpc.vpc_id
        cidr_block = subnet.cidr_block
        zone       = subnet.zone
      }
    ]
  }
}

resource "aws_subnet" "main" {

  for_each = {
    for subnet in flatten([
      for vpc_key, subnets in local.subnet_configs : [
        for subnet in subnets : {
          key    = "${vpc_key}-${subnet.zone}"
          config = subnet
        }
      ]
    ]) : subnet.key => subnet.config
  }

  vpc_id            = each.value.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.zone

  tags = {
    Name = each.key
  }
}

