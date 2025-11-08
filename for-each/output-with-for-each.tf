# First define some instances using for_each
variable "instance_configs" {
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

resource "aws_instance" "servers" {
  for_each      = var.instance_configs
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
output "instance_ips" {
  value = {
    for key, instance in aws_instance.servers : key => instance.private_ip
  }
}

# Alternative way using for_each directly in the output block
output "instance_details" {
  value = {
    for key, instance in aws_instance.servers : key => {
      instance_id = instance.id
      private_ip  = instance.private_ip
      public_ip   = instance.public_ip
      environment = instance.tags.Environment
    }
  }
}


locals {
  instance_ips = output.instance_ips
  test_value   = output.instance_details
  dev_instances = {
    for name, ip in local.instance_ips :
    name => ip
    if output.instance_details[name].environment == "dev"
  }
}