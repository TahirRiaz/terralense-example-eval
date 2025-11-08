# Test: Complex Transformations Encodings
# Prefix: cte_ (complex_transformations_encodings)

locals {
  # Basic type assignments
  cte_string_var = "test_string"
  cte_number_var = 42
  cte_bool_var   = true

  # Lists and list operations
  cte_simple_list = ["a", "b", "c"]
  cte_number_list = [1, 2, 3, 4, 5]
  cte_complex_list = [
    {
      name    = "item1"
      enabled = true
      tags    = ["tag1", "tag2"]
    },
    {
      name    = "item2"
      enabled = false
      tags    = ["tag3"]
    }
  ]

  # Maps and nested maps
  cte_simple_map = {
    key1 = "value1"
    key2 = "value2"
  }
  cte_nested_map = {
    level1 = {
      level2 = {
        level3 = "deep_value"
      }
    }
  }

  # String interpolation and concatenation
  cte_interpolated_string = "Hello, ${local.cte_string_var}!"
  cte_concat_string       = "${local.cte_string_var}_suffix"

  # Mathematical operations
  cte_math_add      = 10 + 5
  cte_math_subtract = local.cte_number_var - 2
  cte_math_multiply = 3 * 4
  cte_math_divide   = 20 / 5
  cte_math_modulo   = 17 % 5

  # Complex mathematical expressions
  cte_complex_math = (local.cte_math_add * local.cte_math_subtract) / local.cte_math_divide

  # Conditional expressions
  cte_conditional = local.cte_bool_var ? "true_value" : "false_value"
  cte_nested_conditional = local.cte_number_var > 40 ? (
    local.cte_string_var == "test_string" ? "condition_met" : "string_mismatch"
  ) : "number_too_low"

  # List operations
  cte_list_index  = local.cte_simple_list[1]
  cte_list_slice  = slice(local.cte_number_list, 1, 3)
  cte_list_length = length(local.cte_simple_list)
  cte_joined_list = join(",", local.cte_simple_list)

  # Map operations
  cte_map_lookup = lookup(local.cte_simple_map, "key1", "default")
  cte_map_keys   = keys(local.cte_simple_map)
  cte_map_values = values(local.cte_simple_map)

  # Type conversions
  cte_to_string = tostring(local.cte_number_var)
  cte_to_number = tonumber("42")
  cte_to_bool   = tobool("true")

  # Complex transformations
  cte_transformed_list = [
    for item in local.cte_complex_list :
    {
      id        = "${item.name}_${local.cte_string_var}"
      active    = item.enabled
      tag_count = length(item.tags)
    }
  ]

  # Map transformation with filtering
  cte_filtered_map = {
    for k, v in local.cte_simple_map :
    upper(k) => upper(v)
    if length(v) > 5
  }

  # Nested dynamic blocks preparation
  cte_dynamic_blocks = [
    for item in local.cte_complex_list :
    {
      name = item.name
      tags = [
        for tag in item.tags :
        {
          key   = tag
          value = "${item.name}_${tag}"
        }
      ]
    }
  ]

  # Working with sets
  cte_set_example = toset([
    "unique1",
    "unique2",
    "unique1" # Will be deduplicated
  ])

  # Complex string manipulations
  cte_regex_replace = replace(local.cte_string_var, "/test/", "prod")
  cte_split_string  = split("_", "test_string_split")

  # Combination of multiple operations
  cte_complex_combination = {
    calculated_value = local.cte_math_add * length(local.cte_simple_list)
    nested_condition = local.cte_bool_var ? local.cte_nested_map.level1.level2.level3 : local.cte_string_var
    transformed_data = [
      for idx, item in local.cte_complex_list :
      {
        index     = idx
        name      = upper(item.name)
        tag_count = length(item.tags)
        enabled   = item.enabled
        combined  = "${item.name}_${local.cte_string_var}_${local.cte_number_var}"
      }
      if item.enabled
    ]
  }

  # Date and time handling
  cte_timestamp_example = formatdate("YYYY-MM-DD", timestamp())

  # Base64 encoding/decoding
  cte_base64_encode = base64encode(local.cte_string_var)
  cte_base64_decode = base64decode(local.cte_base64_encode)

  # JSON encoding/decoding
  cte_json_encode = jsonencode(local.cte_complex_list)
  cte_json_decode = jsondecode("{\"key\": \"value\"}")

  # YAML encoding
  cte_yaml_encode = yamlencode({
    key1 = "value1"
    key2 = {
      nested = "value2"
    }
  })
}

# Output block to verify locals
output "cte_locals_test" {
  value = {
    basic_types = {
      string = local.cte_string_var
      number = local.cte_number_var
      bool   = local.cte_bool_var
    }
    lists = {
      simple_list  = local.cte_simple_list
      complex_list = local.cte_complex_list
      list_ops     = local.cte_list_index
    }
    maps = {
      simple_map = local.cte_simple_map
      nested_map = local.cte_nested_map
      map_ops    = local.cte_map_lookup
    }
    strings = {
      interpolated = local.cte_interpolated_string
      concatenated = local.cte_concat_string
    }
    math = {
      basic_ops    = local.cte_math_add
      complex_math = local.cte_complex_math
    }
    conditionals = {
      simple = local.cte_conditional
      nested = local.cte_nested_conditional
    }
    transformations = {
      list_transform = local.cte_transformed_list
      map_transform  = local.cte_filtered_map
      dynamic_blocks = local.cte_dynamic_blocks
    }
    advanced = {
      sets         = local.cte_set_example
      regex        = local.cte_regex_replace
      combinations = local.cte_complex_combination
      timestamps   = local.cte_timestamp_example
      encodings = {
        base64 = local.cte_base64_encode
        json   = local.cte_json_encode
        yaml   = local.cte_yaml_encode
      }
    }
  }
}