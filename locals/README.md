# Locals Test Cases

This directory contains test cases for local value expressions and transformations in Terraform.

## Test Files

### [basic-expressions-operations.tf](basic-expressions-operations.tf)

**Purpose**: Tests basic local value operations and expressions

**Features Tested**:
- String interpolation and concatenation
- Numeric operations (add, subtract, multiply, divide, modulo)
- Conditional expressions (ternary operator)
- List operations (indexing, slicing, length, join)
- Map operations (lookup, keys, values, merge)
- Type conversions (tostring, tonumber, tobool)
- For expressions in locals

**Key Patterns**:
```hcl
locals {
  # String interpolation
  server_name = "server-${var.environment}"

  # Numeric operations
  total_storage = var.instance_count * var.server_config.volume_size

  # Conditional
  environment_tag = var.environment == "production" ? "prod" : "non-prod"

  # List operations
  first_az = var.availability_zones[0]

  # Map operations
  all_tags = merge(var.tags, { Name = local.server_name })

  # For expressions
  instance_tags = {
    for idx in range(var.instance_count) :
    "instance-${idx}" => merge(local.all_tags, {
      InstanceNumber = tostring(idx + 1)
    })
  }
}
```

**Expected Resolution**: Terralense should evaluate all basic operations and resolve local references.

---

### [complex-transformations-encodings.tf](complex-transformations-encodings.tf)

**Purpose**: Tests advanced transformations, encoding functions, and complex data structures

**Features Tested**:
- Complex nested data structures
- List and map transformations
- Filtering with conditionals
- String manipulation (replace, split, regex)
- Type sets and deduplication
- Encoding functions (base64, JSON, YAML)
- Date/time functions
- Nested for expressions

**Key Patterns**:
```hcl
locals {
  # Complex transformation
  transformed_list = [
    for item in local.complex_list :
    {
      id = "${item.name}_${local.string_var}"
      active = item.enabled
      tag_count = length(item.tags)
    }
  ]

  # Filtering
  filtered_map = {
    for k, v in local.simple_map :
    upper(k) => upper(v)
    if length(v) > 5
  }

  # String manipulation
  regex_replace = replace(local.string_var, "/test/", "prod")
  split_string = split("_", "test_string_split")

  # Encoding
  json_encode = jsonencode(local.complex_list)
  base64_encode = base64encode(local.string_var)
  yaml_encode = yamlencode({ key1 = "value1" })

  # Timestamp
  timestamp_example = formatdate("YYYY-MM-DD", timestamp())
}
```

**Expected Resolution**: Terralense should handle complex transformations and encoding functions.

---

### [simple-string-concatenation.tf](simple-string-concatenation.tf)

**Purpose**: Tests simple string operations and lookups

**Features Tested**:
- Basic string concatenation
- Lookup function with defaults
- Simple conditionals
- Map merge operations
- Concat function for lists

**Expected Resolution**: Terralense should resolve basic string and lookup operations.

---

### [advanced-storage-filtering.tf](advanced-storage-filtering.tf)

**Purpose**: Tests complex storage configurations with data source filtering

**Features Tested**:
- Complex conditional expressions
- Data source attribute filtering
- Slice function
- For expressions with data sources
- Dynamic resource creation based on filtered data
- Nested map configurations

**Key Patterns**:
```hcl
locals {
  # Filter data source results
  filtered_sizes = [
    for size in data.azurerm_virtual_machine_sizes.available.sizes : size
    if size.number_of_cores >= 2 &&
       size.memory_in_mb >= 4096 &&
       !startswith(size.name, "Standard_B")
  ]

  # Slice to get subset
  selected_sizes = slice(local.filtered_sizes, 0, 3)

  # Complex storage config
  storage_config = {
    for env in ["dev", "staging", "prod"] : env => {
      tier = env == "prod" ? "Standard" : "Premium"
      lifecycle_rules = {
        logs = {
          days_to_delete = env == "prod" ? 90 : 45
        }
      }
    }
  }
}
```

**Expected Resolution**: Terralense should filter data sources and resolve complex nested configurations.

---

### [deeply-nested-configurations.tf](deeply-nested-configurations.tf)

**Purpose**: Tests very complex nested environment configurations

**Features Tested**:
- 4+ levels of nested objects
- Multiple for expressions at different levels
- Flattening deeply nested structures
- Conditional configurations based on tier
- Complex merging and transformations
- Optional attributes in nested objects

**Key Patterns**:
```hcl
locals {
  environment_configs = {
    for env in var.environments : env.name => {
      tier_config = { /* ... */ }
      services = {
        for service_name, service in var.service_config :
        service_name => {
          port_config = [
            for port in service.ports : {
              number = port
              protocol = port == 443 ? "https" : "http"
            }
          ]
        }
      }
    }
  }

  # Flatten nested structure
  service_deployments = flatten([
    for env_name, env_config in local.environment_configs : [
      for service_name, service in env_config.services : [
        for port_config in service.port_config : {
          deployment_key = "${env_name}-${service_name}-${port_config.number}"
          # ...
        }
      ] if service.enabled
    ]
  ])
}
```

**Expected Resolution**: Terralense should resolve deeply nested structures and flattening operations.

---

### [basic-expressions-operations-duplicate.tf](basic-expressions-operations-duplicate.tf)

**Purpose**: Duplicate of basic-expressions-operations.tf (kept for reference)

## Common Patterns

### String Operations
```hcl
locals {
  interpolated = "Hello ${var.name}"
  concatenated = "${var.prefix}-${var.suffix}"
  upper_case = upper("hello")
  replaced = replace("hello-world", "-", "_")
  split_result = split("-", "hello-world")
}
```

### Numeric Operations
```hcl
locals {
  sum = var.a + var.b
  product = var.a * var.b
  division = var.a / var.b
  modulo = var.a % var.b
}
```

### Conditional Expressions
```hcl
locals {
  result = condition ? true_value : false_value
  nested = condition1 ? (
    condition2 ? value1 : value2
  ) : value3
}
```

### Collection Operations
```hcl
locals {
  # Lists
  first = var.list[0]
  length_val = length(var.list)
  joined = join(",", var.list)

  # Maps
  value = lookup(var.map, "key", "default")
  keys_list = keys(var.map)
  values_list = values(var.map)
  merged = merge(var.map1, var.map2)
}
```

### For Expressions
```hcl
locals {
  # List transformation
  transformed = [for item in var.list : upper(item)]

  # Map transformation
  mapped = {for k, v in var.map : k => upper(v)}

  # Filtering
  filtered = [for item in var.list : item if length(item) > 5]

  # Nested
  nested = [
    for outer in var.list : [
      for inner in outer : transform(inner)
    ]
  ]
}
```

## Testing Checklist

When analyzing these files, Terralense should:

- [ ] Resolve string interpolation
- [ ] Evaluate numeric operations
- [ ] Resolve conditional (ternary) expressions
- [ ] Handle list indexing and slicing
- [ ] Resolve map lookups
- [ ] Support merge operations
- [ ] Handle for expressions
- [ ] Filter with conditional clauses
- [ ] Flatten nested structures
- [ ] Resolve local-to-local references
- [ ] Handle encoding functions (base64, JSON, YAML)
- [ ] Process date/time functions
- [ ] Support regex operations
- [ ] Evaluate type conversion functions
