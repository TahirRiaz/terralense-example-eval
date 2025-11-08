# Splat Expressions Test Cases

This directory contains test cases for splat operator usage in Terraform.

## Test Files

### [simple-splat-expression.tf](simple-splat-expression.tf)

**Purpose**: Tests the splat operator (`[*]`) for extracting attributes from lists of resources

**Features Tested**:
- Splat expressions on count-based resources
- Attribute extraction using splat
- Splat in outputs
- Splat in locals
- Nested attribute access with splat

**Key Patterns**:
```hcl
resource "aws_instance" "test_servers" {
  count = 3
  # ...
}

# Extract all AMI IDs
output "all_instance_ids" {
  value = aws_instance.test_servers[*].ami
}

# Nested attribute access
locals {
  server_names = aws_instance.test_servers[*].tags.Name
}
```

**Expected Resolution**: Terralens should expand the splat expression and return a list of the requested attributes from all instances.

## Common Patterns

### Splat Operator Syntax
The splat operator `[*]` is shorthand for a for expression:

```hcl
# These are equivalent:
aws_instance.server[*].id
[for s in aws_instance.server : s.id]
```

### Use Cases

#### Extracting Single Attributes
```hcl
# Get all instance IDs
instance_ids = aws_instance.web[*].id
```

#### Nested Attributes
```hcl
# Get all instance names from tags
instance_names = aws_instance.web[*].tags.Name
```

#### In Outputs
```hcl
output "private_ips" {
  value = aws_instance.server[*].private_ip
}
```

#### In Locals
```hcl
locals {
  all_arns = aws_s3_bucket.buckets[*].arn
}
```

### Splat vs For Expression

Splat is simpler but less flexible:

```hcl
# Splat - simple attribute extraction
aws_instance.server[*].id

# For expression - can transform
[for s in aws_instance.server : upper(s.id)]

# For expression - can filter
[for s in aws_instance.server : s.id if s.tags.Environment == "prod"]
```

## Testing Checklist

When analyzing these files, Terralens should:

- [ ] Recognize splat operator syntax `[*]`
- [ ] Expand splat to extract attributes from all instances
- [ ] Handle count-based resource references with splat
- [ ] Support nested attribute access (e.g., `[*].tags.Name`)
- [ ] Resolve splat expressions in outputs
- [ ] Resolve splat expressions in locals
- [ ] Return correct list type for splat results
- [ ] Handle splat on empty resource lists
