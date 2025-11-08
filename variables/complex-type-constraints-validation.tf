# # Basic variable types
variable "environment" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, or prod."
  }
}

variable "db_username" {
  type        = string
  description = "Database username for authentication"
  default     = "dbadmin"

  validation {
    condition     = length(var.db_username) >= 3 && length(var.db_username) <= 16
    error_message = "Database username must be between 3 and 16 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z]", var.db_username))
    error_message = "Database username must start with a letter."
  }

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_username))
    error_message = "Database username can only contain letters, numbers, and underscores after the first character."
  }
}

variable "region" {
  type    = string
  default = "us-west-2"
}

variable "instance_count" {
  type    = number
  default = 5
}


# Complex map with nested structures
variable "service_config" {
  type = map(object({
    name = string
    config = object({
      enabled    = bool
      port_range = list(number)
      tags       = map(string)
      components = set(string)
    })
    scaling = object({
      min     = number
      max     = number
      desired = number
      metrics = map(object({
        threshold = number
        operator  = string
      }))
    })
  }))

  default = {
    primary = {
      name = "service-primary"
      config = {
        enabled    = true
        port_range = [1000, 1100, 1200]
        tags = {
          "env"     = "production"
          "version" = "v1.2.3"
          "region"  = "us-west-2"
        }
        components = ["web", "api", "cache"]
      }
      scaling = {
        min     = 2
        max     = 10
        desired = 4
        metrics = {
          cpu = {
            threshold = 75
            operator  = "GreaterThanThreshold"
          }
          memory = {
            threshold = 85
            operator  = "GreaterThanThreshold"
          }
        }
      }
    }
  }
}

# List with complex type definitions
variable "service_definitions" {
  type = list(object({
    id         = string
    name       = string
    endpoints  = list(string)
    weight     = number
    properties = map(string)
  }))

  default = [
    {
      id        = "svc-web-001"
      name      = "web-service"
      endpoints = ["api.example.com:8080/v1", "api.example.com:8081/v2"]
      weight    = 100
      properties = {
        "deployment_id" = "123456789"
        "priority"      = "1"
        "tier"          = "frontend"
      }
    },
    {
      id        = "svc-api-001"
      name      = "api-service"
      endpoints = ["internal.example.com:9000/api"]
      weight    = 50
      properties = {
        "deployment_id" = "987654321"
        "priority"      = "2"
        "tier"          = "backend"
      }
    }
  ]
}

# Complex type definitions with nested objects
variable "cluster_config" {
  type = object({
    instance_types = list(object({
      name = string
      specs = object({
        vcpu   = number
        memory = number
        storage = object({
          type = string
          size = number
        })
      })
      tags = map(string)
    }))
    networking = object({
      vpc_config = object({
        cidr_blocks = list(string)
        zones       = set(string)
        peering     = map(bool)
      })
      security = map(list(string))
    })
  })

  default = {
    instance_types = [
      {
        name = "compute-optimized"
        specs = {
          vcpu   = 4
          memory = 8
          storage = {
            type = "ssd"
            size = 100
          }
        }
        tags = {
          "type" = "compute"
          "tier" = "standard"
        }
      },
      {
        name = "memory-optimized"
        specs = {
          vcpu   = 8
          memory = 32
          storage = {
            type = "ssd"
            size = 200
          }
        }
        tags = {
          "type" = "memory"
          "tier" = "premium"
        }
      }
    ]
    networking = {
      vpc_config = {
        cidr_blocks = ["10.0.0.0/16", "10.1.0.0/16"]
        zones       = ["us-west-2a", "us-west-2b", "us-west-2c"]
        peering = {
          "prod"  = true
          "stage" = false
        }
      }
      security = {
        inbound  = ["80", "443", "22"]
        outbound = ["0-65535"]
      }
    }
  }
}