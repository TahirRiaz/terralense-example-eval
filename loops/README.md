# Loops Test Cases

This directory contains test cases for loop constructs and the `count` meta-argument in Terraform.

## Test Files

### [nested-for-loops-multi-region.tf](nested-for-loops-multi-region.tf)

**Purpose**: Tests deeply nested for expressions across multiple dimensions

**Features Tested**:
- Triple-nested for expressions (environments × regions × instance types)
- Map and list comprehensions
- Flattening nested structures
- For expressions in locals
- For_each with computed values

**Key Patterns**:
```hcl
all_combinations = {
  for env in var.environments : env => {
    for region in var.regions : region => [
      for instance_type in var.instance_types[env] : {
        # ...
      }
    ]
  }
}
```

**Expected Resolution**: Terralense should resolve all nested iterations and produce the final flattened output structure.

---

### [count-meta-argument.tf](count-meta-argument.tf)

**Purpose**: Tests the `count` meta-argument with various patterns

**Features Tested**:
- Basic count usage with `count.index`
- Conditional count expressions
- Count with `length()` function
- Count references in locals
- For expressions over count-based resources
- Lifecycle preconditions with count resources

**Key Patterns**:
```hcl
resource "null_resource" "basic_count" {
  count = var.instance_count
  triggers = {
    instance_id = "instance-${count.index}"
  }
}

locals {
  test = [for MyValue in null_resource.basic_count : MyValue.triggers.instance_id]
}
```

**Expected Resolution**: Terralense should track count expansions and resolve references to count-based resources.

---

### [count-variations.tf](count-variations.tf)

**Purpose**: Tests additional count variations and edge cases

**Features Tested**:
- Count with different variable types
- Complex count expressions
- Count in lifecycle blocks
- Referencing count resources in outputs

**Expected Resolution**: Terralense should handle all count variations consistently.

## Common Patterns

### Count Meta-Argument
The `count` meta-argument creates multiple instances of a resource:
```hcl
resource "aws_instance" "server" {
  count = 3
  # Creates server[0], server[1], server[2]
}
```

### For Expressions
Transform and filter collections:
```hcl
[for item in var.list : transform(item)]
{for key, value in var.map : key => transform(value)}
```

### Nested Iterations
Combine multiple for expressions:
```hcl
flatten([
  for env in var.environments : [
    for region in var.regions : {
      # ...
    }
  ]
])
```

## Testing Checklist

When analyzing these files, Terralense should:

- [ ] Resolve count values correctly
- [ ] Track count.index references
- [ ] Expand count-based resources properly
- [ ] Handle references to count resources (e.g., `resource.name[0]`)
- [ ] Resolve nested for expressions
- [ ] Flatten nested structures correctly
- [ ] Handle range() function
- [ ] Process for expressions in locals
- [ ] Support for_each on computed values
