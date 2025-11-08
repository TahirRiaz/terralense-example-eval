# Resources Test Cases

This directory contains test cases for complex resource configurations with dependencies and advanced patterns.

## Test Files

### [aws-vpc-full-networking-stack.tf](aws-vpc-full-networking-stack.tf)

**Purpose**: Tests a complete AWS VPC networking stack with all components

**Features Tested**:
- Multiple resource types working together
- For_each on resources
- Flattened subnet configurations
- Dynamic blocks in resources
- Route tables with dynamic routes
- NAT gateways and Elastic IPs
- Resource dependencies
- Lifecycle blocks with preconditions
- Complex outputs

**Key Patterns**:
```hcl
resource "aws_vpc" "main" {
  for_each = var.vpc_configs
  cidr_block = each.value.cidr_block
}

resource "aws_subnet" "main" {
  for_each = local.subnet_configs
  vpc_id = each.value.vpc_id

  lifecycle {
    precondition {
      condition = each.value.zone != null
      error_message = "Availability zone must be specified."
    }
  }
}

resource "aws_route_table" "public" {
  dynamic "route" {
    for_each = distinct(flatten([...]))
    content {
      cidr_block = route.value.destination_cidr_block
      gateway_id = route.value.gateway_id
    }
  }
}
```

**Expected Resolution**: Terralens should resolve all resource dependencies, for_each iterations, and dynamic blocks in a complete stack.

---

### [azure-action-group-conditional.tf](azure-action-group-conditional.tf)

**Purpose**: Tests conditional Azure resource creation with dynamic blocks

**Features Tested**:
- Conditional resource creation with count
- Lookup function with defaults
- Dynamic blocks with email receivers
- Resource references with count index
- Try function for conditional outputs

**Key Patterns**:
```hcl
locals {
  action_group_config = lookup(var.action_group_mapping, "default", {
    action_group_name = ""
    email_receivers = []
  })
  action_group_defined = local.action_group_config.action_group_name != "" ? true : false
}

resource "azurerm_monitor_action_group" "secret_expiry" {
  count = local.action_group_defined ? 1 : 0

  dynamic "email_receiver" {
    for_each = local.action_group_config.email_receivers
    content {
      name = email_receiver.value.name
      email_address = email_receiver.value.email_address
    }
  }
}

resource "azurerm_resource_group" "default2" {
  tags = { test = azurerm_monitor_action_group.secret_expiry[0].id }
}
```

**Expected Resolution**: Terralens should handle conditional count, dynamic blocks, and count-indexed resource references.

---

### [azure-multi-resource-complex.tf](azure-multi-resource-complex.tf)

**Purpose**: Tests multiple Azure resources with complex dependencies and data sources

**Features Tested**:
- Data source usage
- Data source filtering
- Resource dependencies across multiple types
- Count with complex expressions
- Container groups with nested blocks
- Storage accounts with lifecycle rules
- Dynamic blocks in storage
- For expressions in tags

**Key Patterns**:
```hcl
data "azurerm_key_vault" "existing" {
  name = "existing-key-vault-${var.environment}"
  resource_group_name = "security-${var.environment}"
}

data "azurerm_key_vault_secrets" "app_secrets" {
  key_vault_id = data.azurerm_key_vault.existing.id
  filter {
    name_prefix = "APP_"
  }
}

resource "azurerm_container_group" "app_instances" {
  count = local.env_count

  tags = merge(local.tags, {
    Siblings = jsonencode([
      for name in local.env_names :
      name if name != local.env_names[count.index]
    ])
  })
}
```

**Expected Resolution**: Terralens should resolve data sources, complex count expressions, and nested resource dependencies.

---

### [flattened-subnet-configs.tf](flattened-subnet-configs.tf)

**Purpose**: Tests flattened subnet configurations with for_each

**Features Tested**:
- Flatten function
- Nested for expressions to create flat map
- For_each with flattened results
- Complex key generation for for_each

**Key Patterns**:
```hcl
resource "aws_subnet" "main" {
  for_each = {
    for subnet in flatten([
      for vpc_key, vpc in local.subnet_configs : [
        for subnet in vpc.subnets : {
          key = "${vpc_key}-${subnet.zone}"
          config = subnet
        }
      ]
    ]) : subnet.key => subnet.config
  }
}
```

**Expected Resolution**: Terralens should flatten nested structures and create the final for_each map.

---

### [nested-for-in-resource-attribute.tf](nested-for-in-resource-attribute.tf)

**Purpose**: Tests nested for expressions directly in resource attributes

**Features Tested**:
- For expressions in resource blocks (not locals)
- Nested for within for
- Invalid Terraform syntax for testing parser

**Note**: This file may contain intentionally invalid syntax to test parser error handling.

## Common Patterns

### Resource Dependencies

#### Implicit Dependencies
```hcl
resource "aws_subnet" "main" {
  vpc_id = aws_vpc.main.id  # Implicit dependency
}
```

#### Explicit Dependencies
```hcl
resource "aws_instance" "web" {
  depends_on = [aws_security_group.allow_web]
}
```

### Lifecycle Blocks

```hcl
resource "aws_instance" "example" {
  lifecycle {
    create_before_destroy = true
    prevent_destroy = true
    ignore_changes = [tags]

    precondition {
      condition = var.instance_count > 0
      error_message = "Must have at least one instance."
    }

    postcondition {
      condition = self.public_ip != ""
      error_message = "Instance must have a public IP."
    }
  }
}
```

### Dynamic Blocks in Resources

```hcl
resource "aws_security_group" "example" {
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port = ingress.value.from_port
      to_port = ingress.value.to_port
      protocol = ingress.value.protocol
    }
  }
}
```

### Resource For_Each

```hcl
resource "aws_instance" "server" {
  for_each = var.server_configs

  ami = each.value.ami
  instance_type = each.value.type

  tags = {
    Name = each.key
  }
}
```

## Testing Checklist

When analyzing these files, Terralens should:

- [ ] Resolve resource dependencies (implicit and explicit)
- [ ] Track for_each on resources
- [ ] Handle count on resources
- [ ] Expand dynamic blocks in resources
- [ ] Resolve resource attribute references
- [ ] Handle resource references with count (e.g., `resource[0]`)
- [ ] Handle resource references with for_each keys
- [ ] Process lifecycle blocks
- [ ] Validate preconditions and postconditions
- [ ] Resolve flatten operations
- [ ] Handle nested for expressions in resource attributes
- [ ] Track data source to resource dependencies
- [ ] Support complex resource stacks
