# Conditionals Test Cases

This directory contains test cases for conditional logic, try functions, and validation patterns in Terraform.

## Test Files

### [try-lookup-realm-selection.tf](try-lookup-realm-selection.tf)

**Purpose**: Tests try function with lookup and realm selection patterns

**Features Tested**:
- Try function for error handling
- Lookup with default values
- Nested conditionals (ternary operators)
- List comprehension with filtering
- Validation blocks on variables
- Complex conditional logic in locals

**Key Patterns**:
```hcl
variable "secret_expiry_alert" {
  type = object({
    realm = optional(string, null)
    # ...
  })

  validation {
    condition = var.secret_expiry_alert == null || var.secret_expiry_alert.realm == null ? true : var.secret_expiry_alert.log_analytics_workspace_id != null
    error_message = "When a valid realm is specified, log_analytics_workspace_id must not be null."
  }
}

locals {
  selected_realm = var.secret_expiry_alert != null
    ? var.secret_expiry_alert.realm
    : null

  selected_realm_config = local.selected_realm != null ? (
    try(
      [for cfg in var.secret_expiry_alert_config : cfg if cfg.realm == local.selected_realm][0],
      null
    )
  ) : null

  monitoring_enabled = local.selected_realm_config != null
}
```

**Expected Resolution**: Terralense should evaluate try function, conditionals, and validation logic.

---

### [complex-vpc-preconditions.tf](complex-vpc-preconditions.tf)

**Purpose**: Tests lifecycle preconditions and complex VPC validation

**Features Tested**:
- Lifecycle preconditions
- Cidrsubnet function
- Complex validation expressions
- Resource lifecycle blocks
- Precondition error messages

**Key Patterns**:
```hcl
resource "aws_subnet" "main" {
  for_each = local.subnet_configs

  lifecycle {
    precondition {
      condition = cidrsubnet(aws_vpc.main[each.value.vpc_key].cidr_block, 8, 0) == each.value.cidr_block
      error_message = "Subnet CIDR must be a valid subdivision of the VPC CIDR."
    }
  }
}

resource "aws_security_group" "complex" {
  lifecycle {
    create_before_destroy = true

    precondition {
      condition = length(local.vpc_configs) > 0
      error_message = "At least one VPC configuration must be provided."
    }
  }
}
```

**Expected Resolution**: Terralense should parse lifecycle blocks and preconditions.

---

### [nested-realm-config-validation.tf](nested-realm-config-validation.tf)

**Purpose**: Tests nested realm configurations with complex validation

**Features Tested**:
- Nested object validation
- Complex conditional chains
- Optional attributes
- Variable validation with nested conditions

**Expected Resolution**: Terralense should handle nested validation and optional attributes.

## Common Patterns

### Conditional Expressions (Ternary Operator)

```hcl
locals {
  # Simple conditional
  result = condition ? true_value : false_value

  # Nested conditional
  tier = var.env == "prod" ? "premium" : (
    var.env == "staging" ? "standard" : "basic"
  )

  # With null
  value = var.optional_var != null ? var.optional_var : "default"
}
```

### Try Function

The `try` function attempts expressions in order until one succeeds:

```hcl
locals {
  # Try to access nested attribute, fallback to default
  value = try(var.config.nested.value, "default")

  # Try multiple approaches
  id = try(
    aws_instance.web[0].id,
    aws_instance.web["primary"].id,
    "no-instance"
  )

  # Try with type conversion
  port = try(tonumber(var.port_string), 8080)
}
```

### Can Function

Tests whether an expression can be evaluated:

```hcl
variable "email" {
  validation {
    condition = can(regex("^[a-zA-Z0-9._%+-]+@", var.email))
    error_message = "Must be a valid email."
  }
}

locals {
  is_valid_cidr = can(cidrhost(var.cidr, 0))
}
```

### Coalesce Function

Returns the first non-null value:

```hcl
locals {
  # Use provided value or fallback
  database_name = coalesce(
    var.custom_db_name,
    var.default_db_name,
    "mydb"
  )
}
```

### Validation Blocks

```hcl
variable "environment" {
  type = string

  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }

  validation {
    condition = length(var.environment) > 0
    error_message = "Environment cannot be empty."
  }
}
```

### Lifecycle Preconditions

```hcl
resource "aws_instance" "web" {
  lifecycle {
    precondition {
      condition = var.instance_count > 0
      error_message = "Must provision at least one instance."
    }

    precondition {
      condition = data.aws_ami.ubuntu.id != ""
      error_message = "AMI must be specified."
    }
  }
}
```

### Lifecycle Postconditions

```hcl
resource "aws_instance" "web" {
  lifecycle {
    postcondition {
      condition = self.public_ip != ""
      error_message = "Instance must have a public IP address."
    }
  }
}
```

### Null Checks

```hcl
locals {
  # Check for null
  has_value = var.optional != null

  # Conditional with null check
  value = var.optional != null ? var.optional : "default"

  # Try with null fallback
  value2 = try(var.config.nested, null)
}
```

### Optional Attributes (Terraform >= 1.3)

```hcl
variable "config" {
  type = object({
    required = string
    optional = optional(string, "default")
    optional_no_default = optional(string)
  })
}

locals {
  # Access optional attributes
  value = var.config.optional  # Returns "default" if not set
  value2 = var.config.optional_no_default  # Returns null if not set
}
```

## Testing Checklist

When analyzing these files, Terralense should:

- [ ] Evaluate ternary conditional expressions
- [ ] Handle nested conditionals
- [ ] Process try() function
- [ ] Process can() function
- [ ] Process coalesce() function
- [ ] Parse validation blocks
- [ ] Handle multiple validations per variable
- [ ] Validate validation conditions
- [ ] Parse lifecycle blocks
- [ ] Handle precondition blocks
- [ ] Handle postcondition blocks
- [ ] Evaluate complex conditional chains
- [ ] Support optional attributes
- [ ] Handle null checks
- [ ] Process regex in validations
- [ ] Support cidrsubnet in validations
- [ ] Resolve self references in postconditions
