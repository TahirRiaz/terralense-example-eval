# Terralens Evaluation Test Suite

This repository contains a comprehensive collection of Terraform test cases designed to evaluate the capabilities of [Terralens](https://github.com/your-org/terralens), a Terraform analysis and linting tool.

## Overview

Terralens is a static analysis tool for Terraform configurations. This test suite validates Terralens's ability to resolve and analyze various Terraform patterns, including:

- Complex variable and local value expressions
- Dynamic blocks and meta-arguments (`count`, `for_each`)
- Nested for loops and transformations
- Splat expressions and data source references
- Conditional logic and try functions
- Resource dependencies and lifecycle rules

## Repository Structure

The test cases are organized into logical categories:

```
terralens-example-eval/
├── loops/                     # Loop and iteration constructs
├── dynamic-blocks/            # Dynamic block generation
├── splat-expressions/         # Splat operator usage
├── for-each/                  # for_each meta-argument
├── variables/                 # Variable types and validation
├── locals/                    # Local value expressions
├── resources/                 # Complex resource configurations
├── data-sources/              # Data source usage
├── conditionals/              # Conditional logic and try functions
└── resolved/                  # Resolved output examples
```

## Test Categories

### 🔁 [Loops](loops/)
Tests for loop constructs, count meta-arguments, and iteration patterns.
- Nested for expressions across multiple dimensions
- Count with conditional logic
- Range-based iterations

### 🔄 [Dynamic Blocks](dynamic-blocks/)
Tests for dynamically generated nested blocks.
- Security group rules generation
- Nested for expression transformations

### ⚡ [Splat Expressions](splat-expressions/)
Tests for the splat operator (`[*]`) in attribute references.
- Simple splat expressions
- Attribute extraction from resource lists

### 🔀 [For Each](for-each/)
Tests for the `for_each` meta-argument.
- Resource iteration with maps
- Output transformations with for_each

### 📋 [Variables](variables/)
Tests for complex variable type constraints and validation.
- Deeply nested object types
- Validation rules
- Optional attributes

### 🎯 [Locals](locals/)
Tests for local value expressions and transformations.
- Basic operations (string, numeric, conditional)
- Complex transformations and encoding
- Nested configurations

### 🏗️ [Resources](resources/)
Tests for complex resource configurations with dependencies.
- Full infrastructure stacks
- Conditional resource creation
- Flattened configurations

### 📊 [Data Sources](data-sources/)
Tests for data source usage and references.
- Multiple data sources
- File decoding (JSON, YAML)
- Dynamic queries

### ❓ [Conditionals](conditionals/)
Tests for conditional logic and error handling.
- Try/lookup patterns
- Lifecycle preconditions
- Complex validation logic

### ✅ [Resolved](resolved/)
Examples of resolved/evaluated output for reference.

## Usage

Each test file is an independent test case that can be analyzed by Terralens. The test cases are designed to:

1. **Validate parsing** - Ensure Terralens can parse complex Terraform syntax
2. **Test resolution** - Verify that Terralens correctly resolves variables, locals, and expressions
3. **Check analysis** - Confirm that Terralens can analyze resource dependencies and data flow

### Running Tests

To analyze a specific test case with Terralens:

```bash
terralens analyze loops/nested-for-loops-multi-region.tf
```

To analyze an entire category:

```bash
terralens analyze loops/
```

To analyze all test cases:

```bash
terralens analyze .
```

## Test File Naming Convention

Test files follow a descriptive naming convention:

```
<feature-being-tested>-<specific-aspect>.tf
```

Examples:
- `nested-for-loops-multi-region.tf` - Tests nested for loops with regions
- `complex-type-constraints-validation.tf` - Tests complex variable types with validation
- `aws-vpc-full-networking-stack.tf` - Tests a complete VPC configuration

## Unique Naming Convention

**Important:** All test files use a **unique prefix naming convention** to prevent naming conflicts when Terralens evaluates files together.

Each test file has a unique 2-4 letter prefix that is applied to ALL objects within that file:
- Variables: `variable "prefix_name"`
- Locals: `local.prefix_name`
- Resources: `resource "type" "prefix_name"`
- Data Sources: `data "type" "prefix_name"`
- Outputs: `output "prefix_name"`

### Example

File `loops/nested-for-loops-multi-region.tf` uses prefix `nfl_`:
```hcl
# Test: Nested For Loops - Multi-Region
# Prefix: nfl_ (nested_for_loops)

variable "nfl_environments" { ... }
locals { nfl_all_combinations = { ... } }
resource "null_resource" "nfl_test_instances" { ... }
```

### Benefits
- ✅ No naming conflicts across test files
- ✅ All 27 tests can be evaluated together
- ✅ Clear identification of which test each object belongs to
- ✅ Terralens can correctly analyze all files simultaneously

### Documentation
- See [UNIQUE-NAMING.md](./UNIQUE-NAMING.md) for detailed information
- See [REFACTORING-PREFIXES.md](./REFACTORING-PREFIXES.md) for complete prefix mapping

## Contributing

To add new test cases:

1. Identify the primary feature being tested
2. Choose a unique 2-4 letter prefix (check [REFACTORING-PREFIXES.md](./REFACTORING-PREFIXES.md) to avoid duplicates)
3. Place the test file in the appropriate category folder
4. Use a descriptive file name following the naming convention
5. Add header comment with test name and prefix (see [UNIQUE-NAMING.md](./UNIQUE-NAMING.md))
6. Prefix ALL objects in your file (variables, locals, resources, outputs, data sources)
7. Update all internal references to use prefixed names
8. Add test case documentation to the category README
9. Update [REFACTORING-PREFIXES.md](./REFACTORING-PREFIXES.md) with your new prefix mapping
10. Ensure the test case is independent and self-contained

## Test Coverage

This suite includes tests for:

- ✅ Variables (all primitive and complex types)
- ✅ Locals (simple and complex expressions)
- ✅ Resources (AWS, Azure, null resources)
- ✅ Data sources
- ✅ Count meta-argument
- ✅ For_each meta-argument
- ✅ Dynamic blocks
- ✅ Splat expressions
- ✅ For expressions
- ✅ Conditional expressions
- ✅ Try/lookup functions
- ✅ Lifecycle blocks
- ✅ Validation rules
- ✅ Nested structures
- ✅ Flattening operations

## Requirements

These test cases use:
- Terraform >= 0.12 (most cases)
- Terraform >= 1.0 (for optional attributes and advanced features)
- Provider: AWS (~> 4.0, ~> 5.0)
- Provider: Azure (various versions)

## License

[Specify your license here]

## Related Projects

- [Terralens](https://github.com/your-org/terralens) - The main Terralens project

## Support

For issues or questions about specific test cases, please open an issue in this repository.
