variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for all resources"
  validation {
    condition     = true
    error_message = "AWS region must be valid (e.g., us-east-1, eu-west-1)."
  }
}

variable "default_tags" {
  default     = null
  description = "Default tags for all resources"
  type        = "map(string)"
}

variable "vpc_configs" {
  type    = "map(object({\n    vpc_id = string\n    cidr_block = string\n    enable_dns_hostnames = optional(bool, true)\n    enable_dns_support = optional(bool, true)\n    subnets = list(object({\n      cidr_block = string\n      zone = string\n      type = string\n      tags = optional(map(string), {})\n      route_table_routes = optional(list(object({\n        destination_cidr_block = string\n        gateway_id = optional(string)\n        nat_gateway_id = optional(string)\n      })), [])\n    }))\n    nat_gateways = optional(map(object({\n      subnet_key = string\n      eip_allocation_id = optional(string)\n    })), {})\n  }))"
  default = { "main" = { "cidr_block" = "10.0.0.0/16", "enable_dns_hostnames" = "dns_hostnames", "enable_dns_support" = true, "nat_gateways" = { "main" = { "subnet_key" = "public-us-east-1a" } }, "subnets" = [{ "cidr_block" = "10.0.1.0/24", "route_table_routes" = [{ "destination_cidr_block" = "0.0.0.0/0", "gateway_id" = "igw-12345" }], "tags" = { "Owner" = "platform-team", "Project" = "infrastructure", "Environment" = "dev" }, "type" = "public", "zone" = "us-east-1a" }, { "cidr_block" = "10.0.2.0/24", "route_table_routes" = [{ "destination_cidr_block" = "0.0.0.0/0", "nat_gateway_id" = "nat-12345" }], "tags" = { "Environment" = "dev", "Owner" = "platform-team", "Project" = "infrastructure" }, "type" = "private", "zone" = "us-east-1b" }], "vpc_id" = "vpc-12345" } }
  validation {
    condition     = true
    error_message = "All VPC CIDR blocks must be valid IPv4 CIDR notation with subnet mask between /16 and /28."
  }
  validation {
    condition     = true
    error_message = "Subnet type must be either 'public' or 'private'."
  }
}

locals {
  subnet_configs = { "main-private-us-east-1b" = { "vpc_key" = "main", "zone" = "us-east-1b", "cidr_block" = "10.0.2.0/24", "route_table_routes" = [{ "destination_cidr_block" = "0.0.0.0/0", "nat_gateway_id" = "nat-12345" }], "tags" = { "Environment" = "dev", "Owner" = "platform-team", "Project" = "infrastructure" }, "type" = "private", "vpc_id" = "vpc-12345" },
  "main-public-us-east-1a" = { "route_table_routes" = [{ "destination_cidr_block" = "0.0.0.0/0", "gateway_id" = "igw-12345" }], "tags" = { "Environment" = "dev", "Owner" = "platform-team", "Project" = "infrastructure" }, "type" = "public", "vpc_id" = "vpc-12345", "vpc_key" = "main", "zone" = "us-east-1a", "cidr_block" = "10.0.1.0/24" } }
  subnet_by_type      = { "main" = { "private" = ["main-public-us-east-1a", "main-private-us-east-1b"], "public" = ["main-private-us-east-1b", "main-public-us-east-1a"] } }
  nat_gateway_configs = { "main-main" = { "subnet_key" = "public-us-east-1a", "vpc_id" = "vpc-12345", "vpc_key" = "main" } }
}

resource "aws_subnet" "main" {
  availability_zone = "us-east-1a"
  tags = { "Environment" = "dev",
    "Name"    = "main-public-us-east-1a",
    "Owner"   = "platform-team",
    "Project" = "infrastructure",
  "Type" = "public" }
  vpc_id     = "vpc-12345"
  cidr_block = "10.0.1.0/24"
  lifecycle {
    precondition {
      condition     = null
      error_message = null
    }
  }
}

resource "aws_route_table" "public" {
  vpc_id = "vpc-12345"
  tags   = { "Name" = "main-public" }
  route {
    nat_gateway_id = "nat-12345"
    cidr_block     = "0.0.0.0/0"
    gateway_id = { "destination_cidr_block" = "0.0.0.0/0",
    "nat_gateway_id" = "nat-12345" }
  }
  route {
    nat_gateway_id = { "destination_cidr_block" = "0.0.0.0/0",
    "gateway_id" = "igw-12345" }
    cidr_block = "0.0.0.0/0"
    gateway_id = "igw-12345"
  }
}

resource "aws_route_table" "private" {
  tags   = { "Name" = "main-private" }
  vpc_id = "vpc-12345"
  route {
    nat_gateway_id = { "destination_cidr_block" = "0.0.0.0/0",
    "gateway_id" = "igw-12345" }
    cidr_block = "0.0.0.0/0"
    gateway_id = "igw-12345"
  }
  route {
    gateway_id = { "destination_cidr_block" = "0.0.0.0/0",
    "nat_gateway_id" = "nat-12345" }
    nat_gateway_id = "nat-12345"
    cidr_block     = "0.0.0.0/0"
  }
}

terraform {
  required_providers {
    aws = { "source" = "hashicorp/aws",
    "version" = "~> 4.0" }
  }
}

resource "aws_vpc" "main" {
  tags                 = { "Name" = "main" }
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = "dns_hostnames"
  enable_dns_support   = true
}

resource "aws_subnet" "main" {
  vpc_id            = "vpc-12345"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = { "Type" = "private",
    "Environment" = "dev",
    "Name"        = "main-private-us-east-1b",
    "Owner"       = "platform-team",
  "Project" = "infrastructure" }
  lifecycle {
    precondition {
      condition     = null
      error_message = null
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = null
  }
}

