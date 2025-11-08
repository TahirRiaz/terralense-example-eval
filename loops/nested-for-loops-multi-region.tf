# Test: Nested For Loops - Multi-Region
# Prefix: nfl_ (nested_for_loops)

# Define test variables
variable "nfl_environments" {
  description = "List of environments to test"
  type        = list(string)
  default     = ["dev", "staging", "prod"]
}

variable "nfl_instance_types" {
  description = "Map of instance types per environment"
  type        = map(list(string))
  default = {
    dev     = ["t2.micro", "t2.small"]
    staging = ["t2.medium", "t2.large"]
    prod    = ["m5.large", "m5.xlarge"]
  }
}

variable "nfl_regions" {
  description = "List of AWS regions"
  type        = list(string)
  default     = ["us-east-1", "us-west-2"]
}

# Local variable to demonstrate nested for expressions
locals {
  # Create a map of all possible combinations
  nfl_all_combinations = {
    for env in var.nfl_environments : env => {
      for region in var.nfl_regions : region => [
        for instance_type in var.nfl_instance_types[env] : {
          environment = env
          region      = region
          instance    = instance_type
          tag         = "${env}-${region}-${instance_type}"
        }
      ]
    }
  }


  # Flatten the nested structure for easier verification
  nfl_flattened_combinations = flatten([
    for env, regions in local.nfl_all_combinations :
    flatten([
      for region, instances in regions :
      instances
    ])
  ])

  # Create a map with unique keys for verification
  nfl_keyed_combinations = {
    for item in local.nfl_flattened_combinations :
    item.tag => item
  }

}

# Output for verification
output "nfl_nested_loop_results" {
  description = "Results of nested for loop operations"
  value       = local.nfl_all_combinations
}

output "nfl_flattened_results" {
  description = "Flattened results for easier verification"
  value       = local.nfl_flattened_combinations
}

output "nfl_keyed_results" {
  description = "Keyed results for direct access testing"
  value       = local.nfl_keyed_combinations
}

# Test resource to verify the loops work in resource creation
resource "null_resource" "nfl_test_instances" {
  for_each = local.nfl_keyed_combinations

  triggers = {
    environment = each.value.environment
    region      = each.value.region
    instance    = each.value.instance
    tag         = each.value.tag
  }
}
