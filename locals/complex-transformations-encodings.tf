locals {
  # Basic type assignments
  string_var = "test_string"
  number_var = 42
  bool_var   = true

  # Lists and list operations
  simple_list = ["a", "b", "c"]
  number_list = [1, 2, 3, 4, 5]
  complex_list = [
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
  simple_map = {
    key1 = "value1"
    key2 = "value2"
  }
  nested_map = {
    level1 = {
      level2 = {
        level3 = "deep_value"
      }
    }
  }

  # String interpolation and concatenation
  interpolated_string = "Hello, ${local.string_var}!"
  concat_string       = "${local.string_var}_suffix"

  # Mathematical operations
  math_add      = 10 + 5
  math_subtract = local.number_var - 2
  math_multiply = 3 * 4
  math_divide   = 20 / 5
  math_modulo   = 17 % 5

  # Complex mathematical expressions
  complex_math = (local.math_add * local.math_subtract) / local.math_divide

  # Conditional expressions
  conditional = local.bool_var ? "true_value" : "false_value"
  nested_conditional = local.number_var > 40 ? (
    local.string_var == "test_string" ? "condition_met" : "string_mismatch"
  ) : "number_too_low"

  # List operations
  list_index  = local.simple_list[1]
  list_slice  = slice(local.number_list, 1, 3)
  list_length = length(local.simple_list)
  joined_list = join(",", local.simple_list)

  # Map operations
  map_lookup = lookup(local.simple_map, "key1", "default")
  map_keys   = keys(local.simple_map)
  map_values = values(local.simple_map)

  # Type conversions
  to_string = tostring(local.number_var)
  to_number = tonumber("42")
  to_bool   = tobool("true")

  # Complex transformations
  transformed_list = [
    for item in local.complex_list :
    {
      id        = "${item.name}_${local.string_var}"
      active    = item.enabled
      tag_count = length(item.tags)
    }
  ]

  # Map transformation with filtering
  filtered_map = {
    for k, v in local.simple_map :
    upper(k) => upper(v)
    if length(v) > 5
  }

  # Nested dynamic blocks preparation
  dynamic_blocks = [
    for item in local.complex_list :
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
  set_example = toset([
    "unique1",
    "unique2",
    "unique1" # Will be deduplicated
  ])

  # Complex string manipulations
  regex_replace = replace(local.string_var, "/test/", "prod")
  split_string  = split("_", "test_string_split")

  # Combination of multiple operations
  complex_combination = {
    calculated_value = local.math_add * length(local.simple_list)
    nested_condition = local.bool_var ? local.nested_map.level1.level2.level3 : local.string_var
    transformed_data = [
      for idx, item in local.complex_list :
      {
        index     = idx
        name      = upper(item.name)
        tag_count = length(item.tags)
        enabled   = item.enabled
        combined  = "${item.name}_${local.string_var}_${local.number_var}"
      }
      if item.enabled
    ]
  }

  # Date and time handling
  timestamp_example = formatdate("YYYY-MM-DD", timestamp())

  # Base64 encoding/decoding
  base64_encode = base64encode(local.string_var)
  base64_decode = base64decode(local.base64_encode)

  # JSON encoding/decoding
  json_encode = jsonencode(local.complex_list)
  json_decode = jsondecode("{\"key\": \"value\"}")

  # YAML encoding
  yaml_encode = yamlencode({
    key1 = "value1"
    key2 = {
      nested = "value2"
    }
  })
}

# Output block to verify locals
output "locals_test" {
  value = {
    basic_types = {
      string = local.string_var
      number = local.number_var
      bool   = local.bool_var
    }
    lists = {
      simple_list  = local.simple_list
      complex_list = local.complex_list
      list_ops     = local.list_index
    }
    maps = {
      simple_map = local.simple_map
      nested_map = local.nested_map
      map_ops    = local.map_lookup
    }
    strings = {
      interpolated = local.interpolated_string
      concatenated = local.concat_string
    }
    math = {
      basic_ops    = local.math_add
      complex_math = local.complex_math
    }
    conditionals = {
      simple = local.conditional
      nested = local.nested_conditional
    }
    transformations = {
      list_transform = local.transformed_list
      map_transform  = local.filtered_map
      dynamic_blocks = local.dynamic_blocks
    }
    advanced = {
      sets         = local.set_example
      regex        = local.regex_replace
      combinations = local.complex_combination
      timestamps   = local.timestamp_example
      encodings = {
        base64 = local.base64_encode
        json   = local.json_encode
        yaml   = local.yaml_encode
      }
    }
  }
}