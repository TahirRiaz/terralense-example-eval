# Test: Nested For in Resource Attribute
# Prefix: nfr_ (nested_for_resource)

variable "nfr_vpc_id" {
  type    = string
  default = "vpc-12345"
}

locals {
  nfr_subnet_configs = {
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

resource "aws_subnet" "nfr_main" {
  for = {
    for name, config in local.nfr_subnet_configs :
    name => {
      for k, v in config :
      k => v
    }
  }
  vpc_id = var.nfr_vpc_id
  tags = {
    for k, v in local.nfr_subnet_configs :
    k => "${k}"
  }
}