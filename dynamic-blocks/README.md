# Dynamic Blocks Test Cases

This directory contains test cases for dynamic block generation in Terraform.

## Test Files

### [azure-security-group-rules.tf](azure-security-group-rules.tf)

**Purpose**: Tests dynamic block generation for Azure Network Security Group rules

**Features Tested**:
- Dynamic blocks with `for_each`
- Accessing iterator values within dynamic blocks
- Locals used as data source for dynamic blocks
- Azure provider resource patterns

**Key Patterns**:
```hcl
resource "azurerm_network_security_group" "example" {
  dynamic "security_rule" {
    for_each = local.security_rules
    content {
      name     = security_rule.value.name
      priority = security_rule.value.priority
      # ...
    }
  }
}
```

**Expected Resolution**: Terralens should expand the dynamic block and resolve all `security_rule.value` references.

---

### [nested-for-expression-transformation.tf](nested-for-expression-transformation.tf)

**Purpose**: Tests nested for expressions that prepare data for dynamic blocks

**Features Tested**:
- Nested for expressions within locals
- Data transformation for dynamic block consumption
- Tag generation patterns

**Key Patterns**:
```hcl
locals {
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
```

**Expected Resolution**: Terralens should resolve the nested for expressions and track the transformed data structure.

## Common Patterns

### Dynamic Blocks
Dynamic blocks allow you to generate repeated nested blocks:

```hcl
resource "aws_security_group" "example" {
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port = ingress.value.port
      to_port   = ingress.value.port
      protocol  = ingress.value.protocol
    }
  }
}
```

### Iterator Names
By default, the iterator is named after the block label (e.g., `ingress`). You can customize it:

```hcl
dynamic "ingress" {
  for_each = var.rules
  iterator = rule
  content {
    from_port = rule.value.port
  }
}
```

### Nested Dynamic Blocks
Dynamic blocks can be nested:

```hcl
dynamic "rule_group" {
  for_each = var.rule_groups
  content {
    dynamic "rule" {
      for_each = rule_group.value.rules
      content {
        # ...
      }
    }
  }
}
```

## Testing Checklist

When analyzing these files, Terralens should:

- [ ] Recognize dynamic block syntax
- [ ] Resolve for_each expressions in dynamic blocks
- [ ] Track iterator variable references (e.g., `security_rule.value`)
- [ ] Handle iterator.key and iterator.value correctly
- [ ] Expand dynamic blocks into their final form
- [ ] Support custom iterator names
- [ ] Handle nested dynamic blocks
- [ ] Resolve locals used as dynamic block data sources
