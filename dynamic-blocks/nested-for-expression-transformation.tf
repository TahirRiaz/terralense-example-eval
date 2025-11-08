# Test: Nested For Expression Transformation
# Prefix: nfe_ (nested_for_expression)

locals {
  # Input data - simple list of items with tags
  nfe_input_list = [
    {
      name = "server1"
      tags = ["prod", "web"]
    },
    {
      name = "server2"
      tags = ["dev"]
    }
  ]

  # Transformed data with nested for expression
  nfe_dynamic_blocks = [
    for item in local.nfe_input_list : {
      name = item.name
      tags = [
        for tag in item.tags : {
          key   = tag
          value = "${item.name}-${tag}"
        }
      ]
    }
  ]
}

# Output to verify the transformation
output "nfe_transformed_data" {
  value = local.nfe_dynamic_blocks
}