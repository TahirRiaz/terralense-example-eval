# Data Sources Test Cases

This directory contains test cases for data source usage and references in Terraform.

## Test Files

### [aws-multi-data-source.tf](aws-multi-data-source.tf)

**Purpose**: Tests multiple AWS data sources with dynamic blocks and filtering

**Features Tested**:
- Multiple data source types
- Data source filters
- For_each on data sources
- Dynamic blocks in data sources (IAM policy document)
- Locals using data source values
- Outputs referencing data sources
- Complex data source queries

**Key Patterns**:
```hcl
# Data source with filters
data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name = "region-name"
    values = [var.aws_regions.us_east_1.name]
  }
}

# Data source with for_each
data "aws_subnet" "selected" {
  for_each = var.subnet_cidrs

  vpc_id = data.aws_vpc.selected.id

  filter {
    name = "cidr-block"
    values = [each.value]
  }
}

# IAM policy with dynamic blocks
data "aws_iam_policy_document" "example" {
  dynamic "statement" {
    for_each = local.iam_policy_statements
    content {
      sid = statement.value.sid
      effect = statement.value.effect
      actions = statement.value.actions
      resources = statement.value.resources
    }
  }
}

# Using data sources in outputs
output "subnet_details" {
  value = {
    for k, subnet in data.aws_subnet.selected : k => {
      id = subnet.id
      cidr_block = subnet.cidr_block
    }
  }
}
```

**Expected Resolution**: Terralens should resolve data source queries, filters, and references to data source attributes.

---

### [json-file-decode.tf](json-file-decode.tf)

**Purpose**: Tests JSON file reading and decoding

**Features Tested**:
- File function
- Jsondecode function
- Path module variable
- Accessing decoded JSON properties in outputs

**Key Patterns**:
```hcl
locals {
  json_data = jsondecode(file("${path.module}/data.json"))
}

output "environment" {
  value = local.json_data.environment
}

output "tags" {
  value = local.json_data.tags
}
```

**Expected Resolution**: Terralens should handle file reading and JSON decoding (or recognize the pattern).

**Note**: This test requires a `data.json` file to exist in the same directory.

## Common Patterns

### Basic Data Sources

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}
```

### Data Source with For_Each

```hcl
data "aws_subnet" "selected" {
  for_each = toset(var.subnet_ids)

  id = each.value
}
```

### Referencing Data Sources

```hcl
resource "aws_instance" "web" {
  ami = data.aws_ami.ubuntu.id
  subnet_id = data.aws_subnet.selected["subnet-1"].id
}
```

### Data Source Filters

```hcl
data "aws_vpc" "selected" {
  filter {
    name = "tag:Environment"
    values = ["production"]
  }

  filter {
    name = "state"
    values = ["available"]
  }
}
```

### Dynamic Blocks in Data Sources

```hcl
data "aws_iam_policy_document" "policy" {
  dynamic "statement" {
    for_each = var.policy_statements
    content {
      actions = statement.value.actions
      resources = statement.value.resources
      effect = statement.value.effect
    }
  }
}
```

### File Functions

```hcl
# Read file as string
locals {
  script = file("${path.module}/script.sh")
}

# Decode JSON
locals {
  config = jsondecode(file("${path.module}/config.json"))
}

# Decode YAML
locals {
  yaml_config = yamldecode(file("${path.module}/config.yaml"))
}

# Template file
data "template_file" "init" {
  template = file("${path.module}/init.tpl")
  vars = {
    cluster_name = var.cluster_name
  }
}
```

## Testing Checklist

When analyzing these files, Terralens should:

- [ ] Recognize data source blocks
- [ ] Parse data source arguments
- [ ] Handle data source filters
- [ ] Support for_each on data sources
- [ ] Resolve data source attribute references
- [ ] Handle dynamic blocks in data sources
- [ ] Process file() function calls
- [ ] Handle jsondecode() function
- [ ] Handle yamldecode() function
- [ ] Support path.module references
- [ ] Resolve data source to resource dependencies
- [ ] Track data source outputs
- [ ] Handle data source references with for_each keys
- [ ] Support template rendering (if applicable)
