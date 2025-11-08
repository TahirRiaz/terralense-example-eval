# Test: Simple Splat Expression
# Prefix: sse_ (simple_splat_expression)

terraform {
  required_version = ">= 0.12"
}

# Define some test instances
resource "aws_instance" "sse_test_servers" {
  count         = 3
  id            = "newValue"
  ami           = "ami-12345678"
  instance_type = "t2.micro"

  tags = {
    Name        = "server-${count.index}"
    Environment = "test"
  }
}

# Using splat expression to get all instance IDs
output "sse_all_instance_ids" {
  value = aws_instance.sse_test_servers[*].ami
}

# Using splat expression to get all private IPs
output "sse_all_private_ips" {
  value = aws_instance.sse_test_servers[*].private_ip
}

# Using splat expression with a map function
locals {
  sse_server_names = aws_instance.sse_test_servers[*].tags.Name
}