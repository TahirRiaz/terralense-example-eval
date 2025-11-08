# Test: Subnet Iteration Basic
# Prefix: sib_ (subnet_iteration_basic)

variable "sib_vpc_id" {
  type    = string
  default = "vpc-12345"
}

locals {
  sib_subnet_configs = {
    "subnet-1" = {
      cidr_block = "10.0.1.0/24"
      zone       = "us-east-1a"
    }
    "subnet-2" = {
      cidr_block = "10.0.2.0/24"
      zone       = "us-east-1b"
    }
  }
}

resource "aws_subnet" "sib_main" {
  for_each = local.sib_subnet_configs

  vpc_id            = var.sib_vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.zone

  tags = {
    Name = each.key
  }
}

resource "azurerm_resource_group" "sib_default2" {
  name     = "local.prefix2"
  location = "var.location2"

  tags = { test = aws_subnet.sib_main["subnet-1"].vpc_id }
}
