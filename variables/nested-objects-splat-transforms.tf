
# Base Variables
variable "environment" {
  type    = string
  default = "development"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Project     = "test"
  }
}



# Test Case 1: Splat Expressions
variable "instances" {
  type = list(object({
    id   = string
    tags = map(string)
  }))
  default = [
    {
      id = "i-123"
      tags = {
        Name = "server1"
      }
    },
    {
      id = "i-456"
      tags = {
        Name = "server2"
      }
    }
  ]
}

# Test Case 2: Complex Type Constraints with Nested Objects
variable "network_config" {
  type = object({
    vpc = object({
      cidr_block = string
      subnets = list(object({
        cidr = string
        zone = string
      }))
    })
    security_groups = map(list(object({
      from_port = number
      to_port   = number
      protocol  = string
    })))
  })
  default = {
    vpc = {
      cidr_block = "10.0.0.0/16"
      subnets = [
        {
          cidr = "10.0.1.0/24"
          zone = "us-west-1a"
        },
        {
          cidr = "10.0.2.0/24"
          zone = "us-west-1b"
        }
      ]
    }
    security_groups = {
      "web" = [
        {
          from_port = 80
          to_port   = 80
          protocol  = "tcp"
        },
        {
          from_port = 443
          to_port   = 443
          protocol  = "tcp"
        }
      ]
    }
  }
}

# Test Case 3: Complex String Templates
locals {
  base_tags = {
    Environment = var.environment
    Project     = var.tags["Project"]
  }
  
  instance_names = [for i in range(3) : format("server-%s-%02d", var.environment, i + 1)]
  
  subnet_config = {
    for subnet in var.network_config.vpc.subnets :
    subnet.zone => {
      cidr = subnet.cidr
      name = "subnet-${substr(subnet.zone, -2, 2)}"
    }
  }

  security_group_rules = flatten([
    for sg_name, rules in var.network_config.security_groups : [
      for rule in rules : {
        name     = sg_name
        port     = rule.from_port == rule.to_port ? rule.from_port : "${rule.from_port}-${rule.to_port}"
        protocol = rule.protocol
      }
    ]
  ])
}

# Test Case 4: Complex Outputs with Transformations
output "network_summary" {
  value = {
    vpc_info = {
      cidr_blocks = {
        vpc     = var.network_config.vpc.cidr_block
        subnets = [for s in var.network_config.vpc.subnets : s.cidr]
      }
      subnet_mapping = local.subnet_config
    }
    security_rules = {
      for rule in local.security_group_rules :
      "${rule.name}-${rule.port}" => rule
    }
    instance_metadata = {
      names       = local.instance_names
      base_tags   = local.base_tags
      instance_ids = var.instances[*].id
    }
  }
}