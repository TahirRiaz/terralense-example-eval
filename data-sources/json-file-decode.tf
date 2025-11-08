# Test: JSON File Decode
# Prefix: jfd_ (json_file_decode)

# New Terraform configuration file
locals {
  jfd_json_data = jsondecode(file("${path.module}/data.json"))
}

output "jfd_environment" {
  value = local.jfd_json_data.environment
}

output "jfd_region" {
  value = local.jfd_json_data.region
}

output "jfd_tags" {
  value = local.jfd_json_data.tags
}