# Terralens Test Catalog

Complete catalog of all test cases in the Terralens evaluation test suite.

## Table of Contents

- [Loops (3 tests)](#loops)
- [Dynamic Blocks (2 tests)](#dynamic-blocks)
- [Splat Expressions (1 test)](#splat-expressions)
- [For Each (2 tests)](#for-each)
- [Variables (2 tests)](#variables)
- [Locals (6 tests)](#locals)
- [Resources (5 tests)](#resources)
- [Data Sources (2 tests)](#data-sources)
- [Conditionals (3 tests)](#conditionals)
- [Resolved (1 test)](#resolved)

**Total: 27 test cases**

---

## Loops

### 1. nested-for-loops-multi-region.tf
**Category**: Loops
**Complexity**: High
**Line Count**: ~84 lines

**Description**: Tests deeply nested for expressions across three dimensions (environments × regions × instance types)

**Features**:
- Triple-nested for expressions
- Flattening nested structures
- Map and list comprehensions
- For_each on null resources
- Multiple output transformations

**Test Data**:
- 3 environments (dev, staging, prod)
- 2 regions (us-east-1, us-west-2)
- 2-3 instance types per environment

**Expected Outputs**:
- `nested_loop_results`: Nested map structure
- `flattened_results`: Flat list of all combinations
- `keyed_results`: Map with unique keys

**Key Challenge**: Resolving 3 levels of nested iteration (18 total combinations)

---

### 2. count-meta-argument.tf
**Category**: Loops
**Complexity**: Medium
**Line Count**: ~135 lines

**Description**: Comprehensive test of the count meta-argument with various patterns

**Features**:
- Basic count with `count.index`
- Conditional count (`condition ? 2 : 0`)
- Count with `length()` function
- For expressions over count-based resources
- Lifecycle preconditions
- Complex count expressions

**Test Data**:
- `instance_count = 1` (default)
- `enable_extra_instances = true`
- 3 subnet CIDRs
- 3 tags

**Resources Created**:
- 4 null_resource types with different count patterns
- Total instances vary based on variables

**Expected Outputs**:
- `basic_count_ids`: List of instance IDs
- `basic_count_names`: Map of instance names
- `conditional_resources`: Conditional resource list
- `subnet_details`: Subnet resource details

**Key Challenge**: Tracking count.index and references to count-based resources

---

### 3. count-variations.tf
**Category**: Loops
**Complexity**: Medium
**Line Count**: ~139 lines

**Description**: Additional count variations and edge cases

**Features**:
- Count with different variable types
- Complex count expressions with modulo
- Count in lifecycle blocks
- Referencing count resources in locals

**Similar to**: count-meta-argument.tf but with variations

**Key Challenge**: Complex count logic and lifecycle interactions

---

## Dynamic Blocks

### 4. azure-security-group-rules.tf
**Category**: Dynamic Blocks
**Complexity**: Low
**Line Count**: ~47 lines

**Description**: Tests dynamic block generation for Azure Network Security Group rules

**Features**:
- Dynamic `security_rule` blocks
- Accessing iterator values
- Azure provider resource

**Test Data**:
- 2 security rules (HTTP on port 80, HTTPS on port 443)

**Resources Created**:
- 1 azurerm_network_security_group with 2 dynamic rules

**Key Challenge**: Expanding dynamic blocks and resolving iterator.value references

---

### 5. nested-for-expression-transformation.tf
**Category**: Dynamic Blocks
**Complexity**: Low
**Line Count**: ~31 lines

**Description**: Tests nested for expressions that transform data for dynamic block usage

**Features**:
- Nested for expressions within locals
- Tag generation patterns

**Test Data**:
- 2 servers with tags

**Expected Output**:
- `transformed_data`: Nested structure with transformed tags

**Key Challenge**: Resolving nested for expressions in data transformation

---

## Splat Expressions

### 6. simple-splat-expression.tf
**Category**: Splat Expressions
**Complexity**: Low
**Line Count**: ~31 lines

**Description**: Tests basic splat operator usage

**Features**:
- Splat on count-based resources
- Attribute extraction
- Nested attribute access (`[*].tags.Name`)

**Test Data**:
- 3 AWS instances created with count

**Expected Outputs**:
- `all_instance_ids`: List of AMI IDs
- `all_private_ips`: List of private IPs

**Locals**:
- `server_names`: Extracted from tags using splat

**Key Challenge**: Expanding splat to extract attributes from all instances

---

## For Each

### 7. output-with-for-each.tf
**Category**: For Each
**Complexity**: Medium
**Line Count**: ~61 lines

**Description**: Tests outputs using for_each with AWS instances

**Features**:
- For_each with map of objects
- Output transformations
- Locals referencing outputs
- Filtering in locals

**Test Data**:
- 2 instance configs (app1: t3.micro/dev, app2: t3.small/prod)

**Expected Outputs**:
- `instance_ips`: Map of private IPs
- `instance_details`: Full instance details

**Locals**:
- `dev_instances`: Filtered instances by environment

**Key Challenge**: Output references in locals and filtering for_each resources

---

### 8. subnet-iteration-basic.tf
**Category**: For Each
**Complexity**: Low
**Line Count**: ~37 lines

**Description**: Basic for_each iteration over subnets

**Features**:
- For_each with locals
- Keyed resource references

**Test Data**:
- 2 subnets in different AZs

**Resources Created**:
- 2 aws_subnet resources
- 1 azurerm_resource_group referencing specific subnet

**Key Challenge**: Resolving keyed resource references (e.g., `aws_subnet.main["subnet-1"]`)

---

## Variables

### 9. complex-type-constraints-validation.tf
**Category**: Variables
**Complexity**: Very High
**Line Count**: ~206 lines

**Description**: Tests extremely complex variable type constraints and multiple validation rules

**Features**:
- Deeply nested object types (4+ levels)
- Multiple validation blocks per variable
- Sets, lists, maps, objects
- Optional attributes
- Regex validation
- Length validation

**Variables Defined**:
- `environment` (string with validation)
- `db_username` (string with 3 validations)
- `service_config` (map of complex objects)
- `service_definitions` (list of objects)
- `cluster_config` (deeply nested object)

**Key Challenge**: Parsing and validating very complex type constraints

---

### 10. nested-objects-splat-transforms.tf
**Category**: Variables
**Complexity**: High
**Line Count**: ~135 lines

**Description**: Tests nested objects with splat expressions and complex transformations

**Features**:
- Nested object variables
- Splat on variable lists
- For expressions with variables
- String templates
- Merge operations
- Complex output transformations

**Variables Defined**:
- `instances` (list of objects)
- `network_config` (nested object with VPC and security groups)

**Expected Output**:
- `network_summary`: Complex nested output with transformations

**Key Challenge**: Resolving nested variable references and splat expressions

---

## Locals

### 11. basic-expressions-operations.tf
**Category**: Locals
**Complexity**: Low
**Line Count**: ~81 lines

**Description**: Tests all basic local value operations

**Features**:
- String interpolation and concatenation
- Numeric operations (+, -, *, /, %)
- Conditional expressions
- List operations (indexing, length, join)
- Map operations (lookup, keys, values, merge)
- Type conversions
- For expressions

**Expected Output**:
- `server_configuration`: Composite object with all computed values

**Key Challenge**: Evaluating all basic operations correctly

---

### 12. complex-transformations-encodings.tf
**Category**: Locals
**Complexity**: High
**Line Count**: ~199 lines

**Description**: Tests advanced transformations, encoding functions, and complex data structures

**Features**:
- Complex nested data structures
- Filtering with conditionals
- String manipulation (replace, split, regex)
- Sets and deduplication
- Base64 encoding/decoding
- JSON encoding/decoding
- YAML encoding
- Timestamp formatting
- Nested for expressions

**Expected Output**:
- `locals_test`: Comprehensive output with all transformations

**Key Challenge**: Handling encoding functions and complex transformations

---

### 13. simple-string-concatenation.tf
**Category**: Locals
**Complexity**: Very Low
**Line Count**: ~81 lines

**Description**: Tests simple string operations and lookups

**Features**:
- Basic string concatenation
- Lookup with defaults
- Simple conditionals
- Concat for lists

**Includes**: Expected resolution in comments

**Key Challenge**: Basic string and lookup resolution

---

### 14. advanced-storage-filtering.tf
**Category**: Locals
**Complexity**: Very High
**Line Count**: ~202 lines

**Description**: Tests complex storage configurations with data source filtering

**Features**:
- Data source filtering
- Slice function
- Complex conditional storage configs
- Count with resources
- Dynamic blocks in storage
- For expressions with data sources

**Data Sources Used**:
- `azurerm_virtual_machine_sizes`
- `azurerm_key_vault`
- `azurerm_key_vault_secrets`

**Resources Created**:
- Resource groups with count
- Container groups
- Storage accounts with lifecycle rules

**Key Challenge**: Filtering data sources and complex nested configurations

---

### 15. deeply-nested-configurations.tf
**Category**: Locals
**Complexity**: Very High
**Line Count**: ~642 lines

**Description**: Tests extremely complex nested environment configurations (the most complex test)

**Features**:
- 4+ levels of nested objects
- Multiple for expressions at different nesting levels
- Flattening deeply nested structures
- Conditional configurations by tier
- Complex merging
- Optional attributes

**Variables**:
- Complex environment definitions
- Service configurations
- Advanced environment objects with scaling and networking

**Resources Created**:
- ECS clusters and services
- EBS volumes with dynamic blocks
- Security groups with nested dynamic blocks
- VPC endpoints

**Key Challenge**: Resolving 4+ levels of nested for expressions and flattening

**Comment**: Includes resolved examples in block comments

---

### 16. basic-expressions-operations-duplicate.tf
**Category**: Locals
**Complexity**: Low
**Line Count**: ~81 lines

**Description**: Duplicate of test #11 (kept for reference)

---

## Resources

### 17. aws-vpc-full-networking-stack.tf
**Category**: Resources
**Complexity**: Very High
**Line Count**: ~340 lines

**Description**: Complete AWS VPC networking stack with all components

**Features**:
- Multiple resource types
- For_each on resources
- Flattened subnet configurations
- Dynamic route blocks
- NAT gateways and EIPs
- Route table associations
- Lifecycle preconditions
- Complex outputs

**Resources Created**:
- aws_vpc
- aws_subnet
- aws_route_table (public and private)
- aws_route_table_association
- aws_eip
- aws_nat_gateway

**Providers**:
- AWS ~> 4.0
- Provider default tags

**Key Challenge**: Resolving complete infrastructure stack with dependencies

---

### 18. azure-action-group-conditional.tf
**Category**: Resources
**Complexity**: Medium
**Line Count**: ~88 lines

**Description**: Conditional Azure resource creation with dynamic blocks

**Features**:
- Conditional count based on lookup
- Dynamic email_receiver blocks
- Count-indexed resource references
- Try function in outputs

**Resources Created**:
- azurerm_resource_group
- azurerm_monitor_action_group (conditional)

**Expected Output**:
- `monitoring`: Action group details with try function

**Key Challenge**: Conditional count and count-indexed references

---

### 19. azure-multi-resource-complex.tf
**Category**: Resources
**Complexity**: Very High
**Line Count**: ~254 lines

**Description**: Multiple Azure resources with complex dependencies

**Features**:
- Multiple data sources
- Data source filtering
- Count with complex expressions
- Container groups
- Storage accounts with lifecycle rules
- Dynamic blocks
- For expressions in tags (jsonencode)

**Data Sources**:
- azurerm_virtual_machine_sizes
- azurerm_key_vault
- azurerm_key_vault_secrets

**Resources Created**:
- Resource groups (multiple)
- Container groups with count
- Storage accounts with lifecycle rules

**Key Challenge**: Complex resource dependencies and data source usage

---

### 20. flattened-subnet-configs.tf
**Category**: Resources
**Complexity**: Medium
**Line Count**: ~69 lines

**Description**: Tests flattened subnet configurations with for_each

**Features**:
- Flatten function
- Nested for to create flat map
- Complex key generation

**Resources Created**:
- aws_subnet with flattened for_each

**Key Challenge**: Flattening and creating unique keys for for_each

---

### 21. nested-for-in-resource-attribute.tf
**Category**: Resources
**Complexity**: Medium
**Line Count**: ~32 lines

**Description**: Tests nested for expressions in resource attributes (may be invalid syntax)

**Features**:
- For within for in resource block
- Potentially invalid syntax for parser testing

**Note**: May contain intentionally broken syntax

**Key Challenge**: Parser error handling

---

## Data Sources

### 22. aws-multi-data-source.tf
**Category**: Data Sources
**Complexity**: Medium
**Line Count**: ~198 lines

**Description**: Tests multiple AWS data sources with various patterns

**Features**:
- Data source filters
- For_each on data sources
- Dynamic blocks in IAM policy document
- Data source references in outputs

**Data Sources**:
- aws_availability_zones (with filter)
- aws_vpc (with filters)
- aws_subnet (with for_each)
- aws_iam_policy_document (with dynamic blocks)

**Expected Outputs**:
- `availability_zones`: List of AZs
- `vpc_details`: VPC information
- `subnet_details`: All subnet details
- `iam_policy`: Generated policy JSON

**Key Challenge**: For_each on data sources and dynamic IAM policies

---

### 23. json-file-decode.tf
**Category**: Data Sources
**Complexity**: Very Low
**Line Count**: ~16 lines

**Description**: Tests JSON file reading and decoding

**Features**:
- File function
- Jsondecode function
- Path.module reference

**Expected Outputs**:
- `environment`: From JSON
- `region`: From JSON
- `tags`: From JSON

**Dependencies**: Requires `data.json` file

**Key Challenge**: File reading and JSON parsing

---

## Conditionals

### 24. try-lookup-realm-selection.tf
**Category**: Conditionals
**Complexity**: High
**Line Count**: ~140 lines

**Description**: Tests try function with lookup and realm selection

**Features**:
- Try function for error handling
- Lookup with defaults
- Nested conditionals
- List comprehension with filtering
- Variable validation with complex conditions
- Optional attributes

**Variables**:
- `secret_expiry_alert_config` (list of realm configs)
- `secret_expiry_alert` (object with validation)
- `vpc_configs`

**Locals**:
- Realm selection logic with try and conditionals

**Expected Output**: Flattened subnet configuration

**Key Challenge**: Try function and complex conditional logic

---

### 25. complex-vpc-preconditions.tf
**Category**: Conditionals
**Complexity**: High
**Line Count**: ~252 lines

**Description**: Tests lifecycle preconditions and VPC validation

**Features**:
- Multiple validation blocks on variables
- Cidrsubnet function in preconditions
- Lifecycle blocks
- Regex validation
- For_each with complex filtering
- Dynamic blocks with nested cidr_blocks

**Variables**:
- Complex VPC configurations with validation

**Resources Created**:
- aws_vpc
- aws_subnet (with preconditions)
- aws_security_group (with nested dynamic blocks and preconditions)

**Expected Output**:
- `security_group_summary`: Complex summary with computed values

**Key Challenge**: Lifecycle preconditions and complex validation

---

### 26. nested-realm-config-validation.tf
**Category**: Conditionals
**Complexity**: Medium
**Line Count**: Varies

**Description**: Tests nested realm configuration validation

**Features**:
- Nested object validation
- Complex conditionals
- Optional attributes

**Key Challenge**: Nested validation logic

---

## Resolved

### 27. variables-resolved-output.tf
**Category**: Resolved
**Complexity**: N/A
**Line Count**: ~126 lines

**Description**: Example of fully resolved Terraform configuration

**Purpose**: Shows expected output after full resolution

**Features**:
- Type constraints as strings
- Fully evaluated default values
- Resolved locals
- Resolved resources
- Resolved provider config

**Note**: This is expected output, not runnable Terraform

**Key Use**: Reference for testing Terralens resolution output

---

## Summary Statistics

### By Complexity
- Very Low: 2 tests (7%)
- Low: 6 tests (22%)
- Medium: 8 tests (30%)
- High: 6 tests (22%)
- Very High: 5 tests (19%)

### By Category
- Loops: 3 tests
- Dynamic Blocks: 2 tests
- Splat Expressions: 1 test
- For Each: 2 tests
- Variables: 2 tests
- Locals: 6 tests (most)
- Resources: 5 tests
- Data Sources: 2 tests
- Conditionals: 3 tests
- Resolved: 1 test

### By Provider
- AWS: ~14 tests
- Azure: ~8 tests
- Null Provider: ~3 tests
- Provider-agnostic: ~2 tests

### Total Lines of Code
Approximately 3,500+ lines of Terraform across all test cases

## Feature Coverage Matrix

| Feature | Test Count | Files |
|---------|------------|-------|
| For expressions | 20 | Most files |
| Count | 3 | loops/* |
| For_each | 15 | Multiple |
| Dynamic blocks | 8 | Multiple |
| Splat expressions | 5 | Multiple |
| Conditionals | 18 | Multiple |
| Validation | 5 | variables/*, conditionals/* |
| Lifecycle | 6 | Multiple |
| Data sources | 4 | data-sources/*, resources/* |
| Nested objects | 12 | Multiple |
| Flatten | 5 | Multiple |
| Try/Can/Coalesce | 3 | conditionals/* |
| Optional attributes | 4 | Multiple |
| Type conversions | 6 | locals/* |
| Encoding functions | 2 | locals/* |

## Recommended Test Order

For implementing Terralens features, test in this order:

1. **Basic Variables** (simple-string-concatenation.tf)
2. **Basic Locals** (basic-expressions-operations.tf)
3. **Simple Count** (count-meta-argument.tf)
4. **Simple Splat** (simple-splat-expression.tf)
5. **Simple For Each** (subnet-iteration-basic.tf)
6. **Dynamic Blocks** (azure-security-group-rules.tf)
7. **Nested For Loops** (nested-for-loops-multi-region.tf)
8. **Complex Variables** (complex-type-constraints-validation.tf)
9. **Data Sources** (aws-multi-data-source.tf)
10. **Conditionals** (try-lookup-realm-selection.tf)
11. **Complex Transformations** (complex-transformations-encodings.tf)
12. **Flattening** (flattened-subnet-configs.tf)
13. **Full Stack** (aws-vpc-full-networking-stack.tf)
14. **Very Complex** (deeply-nested-configurations.tf)

## Contributing New Tests

When adding new test cases:

1. Choose appropriate category
2. Use descriptive file name
3. Add test to this catalog
4. Update category README
5. Include complexity rating
6. Document expected outputs
7. Add to feature coverage matrix
