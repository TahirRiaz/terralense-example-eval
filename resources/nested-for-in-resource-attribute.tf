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
  for = {
    for name, config in local.subnet_configs :
    name => {
      for k, v in config :
      k => v
    }
  }
  vpc_id = var.vpc_id
  tags = {
    for k, v in local.subnet_configs :
    k => "${k}"
  }
}