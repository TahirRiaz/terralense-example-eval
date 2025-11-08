# Resolved Examples

This directory contains examples of resolved/evaluated Terraform configurations, showing what the final output should look like after variable resolution.

## Test Files

### [variables-resolved-output.tf](variables-resolved-output.tf)

**Purpose**: Shows fully resolved variable values and type definitions

**Features Tested**:
- Resolved variable type definitions (shown as strings)
- Resolved variable default values
- Resolved locals with computed values
- Resolved resource attributes
- Resolved provider configurations

**Key Patterns**:
```hcl
# Original variable definition would be:
# variable "vpc_configs" {
#   type = map(object({ ... }))
# }

# Resolved representation:
variable "vpc_configs" {
  type = "map(object({\n    vpc_id = string\n    ...\n  }))"
  default = {
    "main" = {
      "cidr_block" = "10.0.0.0/16"
      "vpc_id" = "vpc-12345"
      # ...
    }
  }
}

# Resolved locals
locals {
  subnet_configs = {
    "main-public-us-east-1a" = {
      "vpc_key" = "main"
      "zone" = "us-east-1a"
      "cidr_block" = "10.0.1.0/24"
      # ...
    }
  }
}

# Resolved resource
resource "aws_subnet" "main" {
  availability_zone = "us-east-1a"
  vpc_id = "vpc-12345"
  cidr_block = "10.0.1.0/24"
  tags = {
    "Name" = "main-public-us-east-1a"
    "Type" = "public"
  }
}
```

**Expected Resolution**: This file shows what Terralens's output should look like after full evaluation.

## Purpose of Resolved Examples

Resolved examples serve several purposes:

1. **Reference Implementation**: Show what fully evaluated Terraform should look like
2. **Testing Comparison**: Provide expected output for Terralens test validation
3. **Documentation**: Help users understand how Terraform resolves complex expressions
4. **Debugging**: Aid in identifying where resolution differs from expected

## What Gets Resolved

### Variables
- Type constraints become string representations
- Default values are fully evaluated
- Validation rules are kept or removed depending on implementation

### Locals
- All expressions are evaluated
- References to variables are replaced with actual values
- For expressions are expanded
- Conditionals are evaluated

### Resources
- For_each is expanded (or kept with resolved keys)
- Count is expanded (or kept with resolved count value)
- Dynamic blocks are expanded
- Variable and local references are replaced with values
- Expressions are evaluated

### Outputs
- All references are resolved
- Expressions are evaluated

## How to Use These Files

### As Test Fixtures
Compare Terralens output against these files:

```bash
# Run Terralens
terralens resolve input.tf > output.tf

# Compare with expected
diff output.tf resolved/expected.tf
```

### As Documentation
Study these files to understand:
- How complex Terraform expressions resolve
- What the final infrastructure definition looks like
- How references are replaced with values

### As Development Guide
When developing Terralens features:
1. Start with a test case in another category
2. Create the expected resolved output here
3. Implement the feature
4. Validate output matches the expected resolution

## Resolution Strategies

Different tools may use different resolution strategies:

### Full Expansion
Expand all for_each, count, and dynamic blocks into individual resources:
```hcl
# Original
resource "aws_instance" "server" {
  count = 3
  # ...
}

# Fully expanded
resource "aws_instance" "server[0]" { }
resource "aws_instance" "server[1]" { }
resource "aws_instance" "server[2]" { }
```

### Partial Resolution
Keep meta-arguments but resolve their values:
```hcl
# Original
resource "aws_instance" "server" {
  count = var.instance_count
}

# Partially resolved
resource "aws_instance" "server" {
  count = 3
}
```

### Value Resolution Only
Keep structure but resolve variable references:
```hcl
# Original
locals {
  name = "${var.prefix}-${var.environment}"
}

# Value resolved
locals {
  name = "myapp-dev"
}
```

## Notes

- This directory may contain multiple resolution strategies for comparison
- Files here are expected outputs, not runnable Terraform
- Some resolution strategies may be lossy (lose metadata like validation rules)
- Resolution should be deterministic and reproducible

## Adding New Resolved Examples

When adding a new resolved example:

1. Start with a test case from another category
2. Manually evaluate all expressions
3. Document which resolution strategy is used
4. Add comments explaining non-obvious resolutions
5. Update this README with any new patterns
