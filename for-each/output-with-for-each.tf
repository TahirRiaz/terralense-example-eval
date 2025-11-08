# Test: Output With For-Each
# Prefix: owf_ (output_with_foreach)

# First define some instances using for_each
variable "owf_instance_configs" {
  type = map(object({
    instance_type = string
    environment   = string
  }))
  default = {
    "app1" = {
      instance_type = "t3.micro"
      environment   = "dev"
    }
    "app2" = {
      instance_type = "t3.small"
      environment   = "prod"
    }
  }
}

resource "aws_instance" "owf_servers" {
  for_each      = var.owf_instance_configs
  id            = "simulated id"
  private_ip    = "10.0.0.2 simulated"
  public_ip     = "10.0.0.1 simulated"
  ami           = "ami-12345678" # Replace with valid AMI ID
  instance_type = each.value.instance_type

  tags = {
    Name        = each.key
    Environment = each.value.environment
  }
}

# Output block using for_each
output "owf_instance_ips" {
  value = {
    for key, instance in aws_instance.owf_servers : key => instance.private_ip
  }
}

# Alternative way using for_each directly in the output block
output "owf_instance_details" {
  value = {
    for key, instance in aws_instance.owf_servers : key => {
      instance_id = instance.id
      private_ip  = instance.private_ip
      public_ip   = instance.public_ip
      environment = instance.tags.Environment
    }
  }
}


locals {
  owf_instance_ips = output.owf_instance_ips
  owf_test_value   = output.owf_instance_details
  owf_dev_instances = {
    for name, ip in local.owf_instance_ips :
    name => ip
    if output.owf_instance_details[name].environment == "dev"
  }
}