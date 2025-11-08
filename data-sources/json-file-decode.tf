# New Terraform configuration file
locals {
  json_data = jsondecode(file("${path.module}/data.json"))
}

output "environment" {
  value = local.json_data.environment
}

output "region" {
  value = local.json_data.region
}

output "tags" {
  value = local.json_data.tags
}