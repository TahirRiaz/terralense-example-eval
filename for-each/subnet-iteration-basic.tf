variable "vpc_id" {
  type    = string
  default = "vpc-12345"
}

locals {
  subnet_configs = {
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

resource "aws_subnet" "main" {
  for_each = local.subnet_configs

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.zone

  tags = {
    Name = each.key
  }
}

resource "azurerm_resource_group" "default2" {
  name     = "local.prefix2"
  location = "var.location2"

  tags = { test = aws_subnet.main["subnet-1"].vpc_id }
}
