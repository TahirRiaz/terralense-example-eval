locals {
  # Input data - simple list of items with tags
  input_list = [
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
  dynamic_blocks = [
    for item in local.input_list : {
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
output "transformed_data" {
  value = local.dynamic_blocks
}