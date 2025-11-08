# Contributing to Terralens Test Suite

Thank you for your interest in contributing to the Terralens evaluation test suite! This guide will help you add new test cases effectively.

## Table of Contents

- [Before You Start](#before-you-start)
- [Test Case Guidelines](#test-case-guidelines)
- [Adding a New Test Case](#adding-a-new-test-case)
- [File Naming Convention](#file-naming-convention)
- [Documentation Requirements](#documentation-requirements)
- [Code Style](#code-style)
- [Submitting Your Contribution](#submitting-your-contribution)

## Before You Start

### Check for Duplicates

Before creating a new test case:

1. Review [TEST-CATALOG.md](TEST-CATALOG.md) to see if a similar test already exists
2. Check the [feature coverage matrix](TEST-CATALOG.md#feature-coverage-matrix)
3. Browse the relevant category folder

### Identify the Category

Determine which category your test belongs to:

- **loops/** - Count meta-argument, for loops, range expressions
- **dynamic-blocks/** - Dynamic block generation
- **splat-expressions/** - Splat operator (`[*]`)
- **for-each/** - For_each meta-argument
- **variables/** - Variable types, validation, constraints
- **locals/** - Local value expressions and transformations
- **resources/** - Complex resource configurations
- **data-sources/** - Data source usage and queries
- **conditionals/** - Conditional logic, try/can functions
- **resolved/** - Expected resolution examples

If your test doesn't fit any category, propose a new one in your PR.

## Test Case Guidelines

### What Makes a Good Test Case

A good test case should:

1. **Be focused**: Test one primary feature or pattern
2. **Be independent**: Not rely on other test files
3. **Be self-contained**: Include all necessary variables and resources
4. **Be realistic**: Use patterns that appear in real Terraform code
5. **Be documented**: Include comments explaining non-obvious patterns
6. **Have clear expected outcomes**: Document what Terralens should resolve

### Test Complexity Guidelines

Rate your test complexity:

- **Very Low**: Single simple feature (< 50 lines)
- **Low**: Basic feature with 2-3 variations (50-100 lines)
- **Medium**: Multiple related features (100-200 lines)
- **High**: Complex patterns or deep nesting (200-300 lines)
- **Very High**: Comprehensive scenarios (300+ lines)

## Adding a New Test Case

### Step 1: Create the Test File

1. Choose the appropriate category folder
2. Create a new `.tf` file with a descriptive name
3. Write your Terraform configuration

**Example**:
```bash
# Create a new test for complex map transformations
touch locals/complex-map-transformations.tf
```

### Step 2: Write the Test

Your test file should include:

```hcl
# Brief description of what this test validates
# Author: Your Name (optional)
# Related Issue: #123 (if applicable)

# Provider configuration (if needed)
terraform {
  required_version = ">= 1.0"
}

# Variables with defaults
variable "example" {
  type = string
  default = "test-value"

  # Include validation if testing that feature
  validation {
    condition = length(var.example) > 0
    error_message = "Cannot be empty."
  }
}

# Locals with the pattern being tested
locals {
  # Comment explaining the pattern
  transformed = {
    for k, v in var.example : k => upper(v)
  }
}

# Resources (if needed)
resource "null_resource" "test" {
  # ...
}

# Outputs showing expected results
output "result" {
  value = local.transformed
  description = "Expected: map with uppercase values"
}
```

### Step 3: Add Comments

Include comments for:

- Complex expressions
- Non-obvious transformations
- Expected resolution results
- Edge cases being tested

**Good example**:
```hcl
locals {
  # This tests nested for expressions with filtering
  # Expected output: Only enabled services from prod environments
  filtered_services = [
    for env in var.environments : [
      for svc in env.services :
      svc if svc.enabled && env.name == "prod"
    ]
  ]
}
```

### Step 4: Test Your File

Validate your Terraform syntax:

```bash
# Initialize Terraform
terraform init

# Validate syntax
terraform validate

# Optional: Check formatting
terraform fmt -check complex-map-transformations.tf
```

### Step 5: Document the Test

#### Update Category README

Add your test to the category's README.md:

```markdown
### [complex-map-transformations.tf](complex-map-transformations.tf)

**Purpose**: Tests complex map transformations with type conversions

**Features Tested**:
- Map comprehensions
- Type conversions in for expressions
- Nested map access

**Key Patterns**:
```hcl
locals {
  transformed = {
    for k, v in var.config : k => {
      value = upper(v.name)
      count = tonumber(v.count)
    }
  }
}
```

**Expected Resolution**: Terralens should resolve the for expression and type conversions.
```

#### Update TEST-CATALOG.md

Add your test to TEST-CATALOG.md in the appropriate section:

```markdown
### X. complex-map-transformations.tf
**Category**: Locals
**Complexity**: Medium
**Line Count**: ~75 lines

**Description**: Tests complex map transformations with type conversions

**Features**:
- Map comprehensions
- Type conversion functions
- Nested map access

**Expected Output**:
- `result`: Transformed map with converted types

**Key Challenge**: Resolving type conversions within for expressions
```

Update the summary statistics and feature coverage matrix as needed.

## File Naming Convention

### Format

```
<feature-being-tested>-<specific-aspect>[-<provider>].tf
```

### Examples

Good names:
- ✅ `nested-for-loops-multi-region.tf`
- ✅ `complex-type-constraints-validation.tf`
- ✅ `aws-vpc-full-networking-stack.tf`
- ✅ `try-lookup-realm-selection.tf`

Avoid:
- ❌ `test1.tf` (too generic)
- ❌ `my-test.tf` (not descriptive)
- ❌ `awesome-terraform-config.tf` (vague)

### Naming Guidelines

1. **Use hyphens** to separate words (kebab-case)
2. **Be specific** about what's being tested
3. **Include provider** if provider-specific (aws-, azure-, gcp-)
4. **Keep it concise** but descriptive (3-5 words)
5. **Use present tense** descriptors

## Documentation Requirements

Every new test must include:

### 1. In-File Comments

```hcl
# Test: Complex Map Transformations
# Category: Locals
# Complexity: Medium
# Purpose: Validates Terralens can resolve map comprehensions with type conversions

locals {
  # Transform input map to uppercase keys with numeric values
  # Input: { "app1" = { name = "web", count = "5" } }
  # Expected: { "APP1" = { name = "web", count = 5 } }
  transformed = {
    for k, v in var.config : upper(k) => {
      name = v.name
      count = tonumber(v.count)
    }
  }
}
```

### 2. Category README Entry

Add a section to the category's README.md (see Step 5 above).

### 3. TEST-CATALOG Entry

Add a detailed entry to TEST-CATALOG.md (see Step 5 above).

### 4. Optional: Expected Resolution

For complex tests, consider adding expected resolution:

```hcl
/*
Given inputs:
  var.config = {
    "app1" = { name = "web", count = "5" }
  }

Expected resolution:
  local.transformed = {
    "APP1" = {
      name = "web"
      count = 5
    }
  }
*/
```

## Code Style

### Formatting

- Use `terraform fmt` to format your code
- Use 2-space indentation
- Keep lines under 120 characters when possible

### Variable Defaults

Always provide default values for testing:

```hcl
variable "environment" {
  type = string
  default = "dev"  # Always include default
}
```

### Naming

- Use descriptive variable and resource names
- Use snake_case for variables and locals
- Use meaningful resource names (not `foo`, `bar`)

**Good**:
```hcl
variable "instance_configs" {
  type = map(object({
    instance_type = string
    environment = string
  }))
}

locals {
  filtered_instances = [
    for key, config in var.instance_configs :
    config if config.environment == "prod"
  ]
}
```

**Avoid**:
```hcl
variable "x" {  # Too short
  type = map(any)  # Too generic
}

locals {
  foo = [for i in var.x : i if i.bar == "baz"]  # Not descriptive
}
```

### Comments

- Comment complex logic
- Explain expected outcomes
- Document edge cases
- Use inline comments sparingly

## Submitting Your Contribution

### Checklist

Before submitting your PR:

- [ ] Test file follows naming convention
- [ ] Terraform syntax is valid (`terraform validate`)
- [ ] Code is formatted (`terraform fmt`)
- [ ] In-file comments explain the test
- [ ] Category README updated
- [ ] TEST-CATALOG.md updated
- [ ] Feature coverage matrix updated (if new feature)
- [ ] Complexity rating assigned
- [ ] No sensitive data (credentials, IPs, etc.)

### Pull Request

1. Fork the repository
2. Create a feature branch (`git checkout -b add-map-transformations-test`)
3. Add your test file
4. Update documentation
5. Commit with a clear message
6. Push to your fork
7. Create a Pull Request

### PR Description Template

```markdown
## Description
Brief description of the new test case.

## Test Details
- **Category**: Locals
- **Complexity**: Medium
- **Features Tested**: Map comprehensions, type conversions
- **File**: locals/complex-map-transformations.tf

## Checklist
- [x] Test file created
- [x] Syntax validated
- [x] Documentation updated
- [x] TEST-CATALOG.md updated

## Related Issue
Closes #123 (if applicable)
```

## Getting Help

- Open an issue for questions
- Check existing tests for examples
- Review TEST-CATALOG.md for patterns
- Ask in discussions

## License

By contributing, you agree that your contributions will be licensed under the same license as this project.

Thank you for contributing! 🎉
