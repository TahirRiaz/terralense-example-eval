
variable "environment" {
  type    = string
  default = "dev"
}


variable "app_config" {
  type    = "object({\n  name       = string\n  port       = number\n  enable_ssl = bool\n})"
  default = { "name" = "myapp", "port" = 8080, "enable_ssl" = true }
}


variable "instance_sizes" {
  type    = "map(string)"
  default = { "medium" = "t3.small", "small" = "t3.micro", "large" = "t3.medium" }
}




variable "region" {
  type    = string
  default = "us-west-2"
}

















