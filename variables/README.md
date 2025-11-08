# Variables Test Cases

This directory contains test cases for complex variable type constraints and validation in Terraform.

## Test Files

### [complex-type-constraints-validation.tf](complex-type-constraints-validation.tf)

**Purpose**: Tests deeply nested object types with validation rules

**Features Tested**:
- Complex variable type constraints (objects, maps, lists, sets)
- Multiple validation blocks per variable
- Regex validation
- Length validation
- Nested object structures (3+ levels deep)
- Optional attributes
- Map of objects with nested configurations

**Key Patterns**:
```hcl
variable "db_username" {
  type = string

  validation {
    condition     = length(var.db_username) >= 3 && length(var.db_username) <= 16
    error_message = "Database username must be between 3 and 16 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z]", var.db_username))
    error_message = "Database username must start with a letter."
  }
}

variable "service_config" {
  type = map(object({
    name = string
    config = object({
      enabled = bool
      port_range = list(number)
      components = set(string)
    })
    scaling = object({
      min = number
      max = number
      metrics = map(object({
        threshold = number
        operator  = string
      }))
    })
  }))
}
```

**Expected Resolution**: Terralense should parse complex type constraints, validate structure, and resolve nested attribute references.

---

### [nested-objects-splat-transforms.tf](nested-objects-splat-transforms.tf)

**Purpose**: Tests nested objects with splat expressions and string templates

**Features Tested**:
- Nested object variable definitions
- Splat expressions on variable lists
- For expressions transforming nested variables
- String templates with variable interpolation
- Merge function with variable maps
- Complex output transformations

**Key Patterns**:
```hcl
variable "instances" {
  type = list(object({
    id   = string
    tags = map(string)
  }))
}

variable "network_config" {
  type = object({
    vpc = object({
      cidr_block = string
      subnets = list(object({
        cidr = string
        zone = string
      }))
    })
    security_groups = map(list(object({
      from_port = number
      to_port   = number
      protocol  = string
    })))
  })
}

output "network_summary" {
  value = {
    instance_ids = var.instances[*].id
    subnet_cidrs = [for s in var.network_config.vpc.subnets : s.cidr]
  }
}
```

**Expected Resolution**: Terralense should resolve nested object references, splat expressions, and for transformations.

## Common Patterns

### Variable Type Constraints

#### Primitive Types
```hcl
variable "example" {
  type = string  # or number, bool
}
```

#### Collection Types
```hcl
variable "list_example" {
  type = list(string)
}

variable "map_example" {
  type = map(number)
}

variable "set_example" {
  type = set(string)
}
```

#### Object Types
```hcl
variable "object_example" {
  type = object({
    name = string
    port = number
    enabled = bool
  })
}
```

#### Nested Structures
```hcl
variable "complex" {
  type = map(object({
    name = string
    config = object({
      settings = map(string)
      ports = list(number)
    })
  }))
}
```

### Validation Rules

```hcl
variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "email" {
  type = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.email))
    error_message = "Must be a valid email address."
  }
}
```

### Optional Attributes (Terraform >= 1.3)

```hcl
variable "config" {
  type = object({
    required_field = string
    optional_field = optional(string, "default_value")
  })
}
```

## Testing Checklist

When analyzing these files, Terralense should:

- [ ] Parse all primitive types (string, number, bool)
- [ ] Parse collection types (list, map, set)
- [ ] Parse object type constraints
- [ ] Handle deeply nested object structures (3+ levels)
- [ ] Resolve variable references in other blocks
- [ ] Validate type constraint syntax
- [ ] Parse validation blocks
- [ ] Handle multiple validation blocks per variable
- [ ] Support optional attributes
- [ ] Resolve default values
- [ ] Track variable.attribute references
- [ ] Handle splat on variable lists
- [ ] Support for expressions on variables
