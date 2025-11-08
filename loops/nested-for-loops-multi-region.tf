# Define test variables
variable "environments" {
  description = "List of environments to test"
  type        = list(string)
  default     = ["dev", "staging", "prod"]
}

variable "instance_types" {
  description = "Map of instance types per environment"
  type        = map(list(string))
  default = {
    dev     = ["t2.micro", "t2.small"]
    staging = ["t2.medium", "t2.large"]
    prod    = ["m5.large", "m5.xlarge"]
  }
}

variable "regions" {
  description = "List of AWS regions"
  type        = list(string)
  default     = ["us-east-1", "us-west-2"]
}

# Local variable to demonstrate nested for expressions
locals {
  # Create a map of all possible combinations
  all_combinations = {
    for env in var.environments : env => {
      for region in var.regions : region => [
        for instance_type in var.instance_types[env] : {
          environment = env
          region      = region
          instance    = instance_type
          tag         = "${env}-${region}-${instance_type}"
        }
      ]
    }
  }


  # Flatten the nested structure for easier verification
  flattened_combinations = flatten([
    for env, regions in local.all_combinations :
    flatten([
      for region, instances in regions :
      instances
    ])
  ])

  # Create a map with unique keys for verification
  keyed_combinations = {
    for item in local.flattened_combinations :
    item.tag => item
  }

}

# Output for verification
output "nested_loop_results" {
  description = "Results of nested for loop operations"
  value       = local.all_combinations
}

output "flattened_results" {
  description = "Flattened results for easier verification"
  value       = local.flattened_combinations
}

output "keyed_results" {
  description = "Keyed results for direct access testing"
  value       = local.keyed_combinations
}

# Test resource to verify the loops work in resource creation
resource "null_resource" "test_instances" {
  for_each = local.keyed_combinations

  triggers = {
    environment = each.value.environment
    region      = each.value.region
    instance    = each.value.instance
    tag         = each.value.tag
  }
}