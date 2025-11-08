# For Each Test Cases

This directory contains test cases for the `for_each` meta-argument in Terraform.

## Test Files

### [output-with-for-each.tf](output-with-for-each.tf)

**Purpose**: Tests outputs that use for_each with resource references

**Features Tested**:
- For_each with map input
- Accessing for_each resources using `each.key` and `each.value`
- For expressions in outputs referencing for_each resources
- Locals referencing output values
- Filtering for_each resources in locals

**Key Patterns**:
```hcl
resource "aws_instance" "servers" {
  for_each = var.instance_configs

  instance_type = each.value.instance_type
  tags = {
    Name = each.key
  }
}

output "instance_ips" {
  value = {
    for key, instance in aws_instance.servers : key => instance.private_ip
  }
}

locals {
  dev_instances = {
    for name, ip in local.instance_ips :
    name => ip
    if output.instance_details[name].environment == "dev"
  }
}
```

**Expected Resolution**: Terralens should resolve for_each iterations, track `each.key` and `each.value` references, and handle output references in locals.

---

### [subnet-iteration-basic.tf](subnet-iteration-basic.tf)

**Purpose**: Tests basic for_each iteration over subnets

**Features Tested**:
- For_each with local values
- Accessing each.key and each.value in resource attributes
- Resource references with for_each keys

**Key Patterns**:
```hcl
locals {
  subnet_configs = {
    "subnet-1" = {
      cidr_block = "10.0.1.0/24"
      zone       = "us-east-1a"
    }
  }
}

resource "aws_subnet" "main" {
  for_each = local.subnet_configs

  cidr_block = each.value.cidr_block
  tags = {
    Name = each.key
  }
}

# Reference specific instance
resource "azurerm_resource_group" "default2" {
  tags = { test = aws_subnet.main["subnet-1"].vpc_id }
}
```

**Expected Resolution**: Terralens should expand for_each and resolve keyed resource references.

## Common Patterns

### For_Each Meta-Argument
The `for_each` meta-argument creates instances based on a map or set:

```hcl
resource "aws_instance" "server" {
  for_each = {
    web = "t3.micro"
    api = "t3.small"
  }

  instance_type = each.value
  tags = {
    Name = each.key  # "web" or "api"
  }
}
```

### Accessing For_Each Resources

#### By Key
```hcl
aws_instance.server["web"].id
```

#### All Instances
```hcl
values(aws_instance.server)[*].id
```

#### In For Expressions
```hcl
{
  for key, instance in aws_instance.server :
  key => instance.private_ip
}
```

### For_Each vs Count

| Feature | for_each | count |
|---------|----------|-------|
| Index/Key | String key | Numeric index |
| Stability | Stable (keyed) | Unstable (index-based) |
| Access | `resource["key"]` | `resource[0]` |
| Best for | Maps, sets | Lists, simple duplication |

### Input Types

For_each accepts:
- **Map**: `for_each = { key1 = value1, key2 = value2 }`
- **Set**: `for_each = toset(["item1", "item2"])`
- **Not allowed**: Lists (must convert to set)

## Testing Checklist

When analyzing these files, Terralens should:

- [ ] Recognize for_each meta-argument
- [ ] Resolve for_each with map inputs
- [ ] Resolve for_each with set inputs
- [ ] Track each.key references
- [ ] Track each.value references
- [ ] Handle keyed resource references (e.g., `resource["key"]`)
- [ ] Support for expressions over for_each resources
- [ ] Handle for_each resources in outputs
- [ ] Resolve locals referencing for_each resources
- [ ] Filter for_each resources with conditionals
