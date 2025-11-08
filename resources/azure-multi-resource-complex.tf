# Test: Azure Multi Resource Complex
# Prefix: amr_ (azure_multi_resource)

variable "amr_environments" {
  type = list(object({
    name = string
    tier = string
    config = object({
      instance_count = number
      multi_az       = bool
    })
  }))
  default = [
    {
      name = "dev"
      tier = "basic"
      config = {
        instance_count = 1
        multi_az       = false
      }
    },
    {
      name = "prod"
      tier = "premium"
      config = {
        instance_count = 3
        multi_az       = true
      }
    }
  ]
}

variable "amr_service_config" {
  type = map(object({
    enabled  = bool
    settings = map(string)
    ports    = list(number)
  }))
  default = {
    web = {
      enabled = true
      settings = {
        "cache_ttl"  = "3600"
        "ssl_policy" = "TLS1.2"
      }
      ports = [80, 443]
    }
    api = {
      enabled = true
      settings = {
        "timeout"    = "30"
        "rate_limit" = "100"
      }
      ports = [8080, 8443]
    }
  }
}

variable "amr_tags_config" {
  type = map(map(string))
  default = {
    dev = {
      environment = "development"
      cost_center = "dev-123"
    }
    prod = {
      environment = "production"
      cost_center = "prod-456"
    }
  }
}

locals {
  # Transform environments into a map for easier lookup
  amr_env_map = {
    for env in var.amr_environments : env.name => env
  }

  # Create complex nested configuration for each environment
  amr_environment_configs = {
    for env in var.amr_environments : env.name => {
      tier_config = {
        instance_type = env.tier == "basic" ? "t3.small" : "t3.large"
        max_count     = env.config.instance_count * (env.tier == "basic" ? 1 : 2)
        multi_az      = env.config.multi_az
      }
      services = {
        for service_name, service in var.amr_service_config :
        service_name => {
          enabled = service.enabled && (env.tier == "premium" || service_name == "web")
          port_config = [
            for port in service.ports : {
              number   = port
              protocol = port == 443 || port == 8443 ? "https" : "http"
              priority = port >= 443 ? "high" : "normal"
            }
          ]
          settings = merge(service.settings, {
            environment = env.name
            tier        = env.tier
          })
        }
      }
      tags = merge(
        lookup(var.amr_tags_config, env.name, {}),
        {
          "ManagedBy"   = "Terraform"
          "Environment" = env.name
          "Tier"        = env.tier
        }
      )
    }
  }

  # Create flattened service configurations for each environment
  amr_service_deployments = flatten([
    for env_name, env_config in local.amr_environment_configs : [
      for service_name, service in env_config.services : [
        for port_config in service.port_config : {
          deployment_key = "${env_name}-${service_name}-${port_config.number}"
          environment    = env_name
          service        = service_name
          port           = port_config.number
          protocol       = port_config.protocol
          priority       = port_config.priority
          enabled        = service.enabled
          settings       = service.settings
          tags           = env_config.tags
        }
      ] if service.enabled
    ]
  ])

  # Generate conditional configurations based on environment tier
  amr_premium_configs = {
    for env_name, env_config in local.amr_environment_configs :
    env_name => {
      backup_enabled = env_config.tier_config.multi_az
      monitoring = {
        detailed = true
        interval = env_config.tier_config.multi_az ? 60 : 300
        metrics = [
          "cpu",
          "memory",
          "disk",
          env_config.tier_config.multi_az ? "network" : null
        ]
      }
    } if lookup(local.amr_env_map, env_name).tier == "premium"
  }
}


# Complex nested object with dynamic validation rules
variable "amr_advanced_environments" {
  type = list(object({
    name     = string
    tier     = string
    features = set(string)
    scaling = object({
      min        = number
      max        = number
      target_cpu = number
      custom_metrics = map(object({
        name       = string
        threshold  = number
        comparison = string
        statistic  = string
      }))
    })
    storage = map(object({
      type       = string
      size       = number
      iops       = optional(number)
      throughput = optional(number)
      encryption = object({
        enabled   = bool
        kms_key   = optional(string)
        algorithm = optional(string, "AES256")
      })
    }))
    networking = object({
      vpc_config = object({
        cidr_block = string
        subnets = map(object({
          cidr   = string
          zone   = string
          public = bool
          tags   = map(string)
        }))
      })
      security = object({
        allowed_cidrs = list(string)
        custom_rules = list(object({
          description = string
          from_port   = number
          to_port     = number
          protocol    = string
          self        = bool
          cidr_blocks = optional(list(string), [])
        }))
      })
    })
  }))

  default = [
    {
      name     = "complex-dev"
      tier     = "development"
      features = ["logging", "monitoring", "backup"]
      scaling = {
        min        = 1
        max        = 3
        target_cpu = 70
        custom_metrics = {
          memory = {
            name       = "MemoryUtilization"
            threshold  = 80
            comparison = "GreaterThanThreshold"
            statistic  = "Average"
          }
        }
      }
      storage = {
        primary = {
          type       = "gp3"
          size       = 100
          iops       = 3000
          throughput = 125
          encryption = {
            enabled   = true
            algorithm = "AES256"
          }
        }
        backup = {
          type = "st1"
          size = 500
          encryption = {
            enabled = true
          }
        }
      }
      networking = {
        vpc_config = {
          cidr_block = "10.0.0.0/16"
          subnets = {
            public-1 = {
              cidr   = "10.0.1.0/24"
              zone   = "us-east-1a"
              public = true
              tags = {
                Type = "Public"
                Tier = "Web"
              }
            }
            private-1 = {
              cidr   = "10.0.10.0/24"
              zone   = "us-east-1a"
              public = false
              tags = {
                Type = "Private"
                Tier = "Application"
              }
            }
          }
        }
        security = {
          allowed_cidrs = ["0.0.0.0/0"]
          custom_rules = [
            {
              description = "Allow internal traffic"
              from_port   = 0
              to_port     = 65535
              protocol    = "-1"
              self        = true
            }
          ]
        }
      }
    }
  ]
}

# Advanced locals with complex transformations
locals {
  # Generate normalized environment configurations
  amr_normalized_environments = {
    for env in var.amr_advanced_environments : env.name => {
      config = merge(
        {
          tier     = env.tier
          features = env.features
        },
        # Conditional configuration based on tier
        env.tier == "development" ? {
          is_development = true
          debug_enabled  = true
          retention_days = 7
          } : {
          is_development = false
          debug_enabled  = false
          retention_days = 30
        }
      )

      # Transform storage configurations
      storage_configs = {
        for storage_key, storage in env.storage : storage_key => merge(
          storage,
          {
            normalized_size  = storage.size * (storage.type == "gp3" ? 1 : 0.8)
            performance_tier = can(storage.iops) ? "high" : "standard"
            backup_eligible  = storage.size >= 100
          }
        )
      }

      # Process networking configuration
      network = {
        subnet_configs = {
          for subnet_key, subnet in env.networking.vpc_config.subnets : subnet_key => merge(
            subnet,
            {
              fully_qualified_name = "${env.name}-${subnet_key}"
              route_table          = subnet.public ? "public" : "private"
              nat_required         = !subnet.public
            }
          )
        }

        security_rules = concat(
          env.networking.security.custom_rules,
          [
            # Add default security rules
            {
              description = "Default egress"
              from_port   = 0
              to_port     = 0
              protocol    = "-1"
              self        = false
              cidr_blocks = ["0.0.0.0/0"]
            }
          ]
        )
      }
    }
  }

  # Generate flattened subnet configurations
  amr_flattened_subnets = flatten([
    for env_name, env in local.amr_normalized_environments : [
      for subnet_key, subnet in env.network.subnet_configs : {
        key         = "${env_name}-${subnet_key}"
        environment = env_name
        subnet_name = subnet_key
        cidr        = subnet.cidr
        zone        = subnet.zone
        is_public   = subnet.public
        tags = merge(
          subnet.tags,
          {
            Environment = env_name
            ManagedBy   = "Terraform"
            NetworkTier = subnet.public ? "Public" : "Private"
          }
        )
      }
    ]
  ])

  # Generate conditional monitoring configurations
  amr_monitoring_configs = {
    for env_name, env in local.amr_normalized_environments : env_name => {
      metrics_enabled  = contains(env.config.features, "monitoring")
      retention_period = env.config.retention_days
      alert_endpoints  = env.config.is_development ? ["dev-team@example.com"] : ["prod-team@example.com", "oncall@example.com"]
      dashboard = {
        widgets = flatten([
          for storage_key, storage in env.storage_configs : [
            {
              title = "${storage_key} - Storage Metrics"
              metrics = concat(
                ["StorageUtilization", "IOPs"],
                storage.performance_tier == "high" ? ["Throughput", "LatencyP99"] : ["Latency"]
              )
            }
          ]
        ])
      }
    }
  }
}


# Reference data sources needed by the resources
data "aws_availability_zones" "amr_available" {
  state = "available"
}

# Base infrastructure resources
resource "aws_vpc" "amr_main" {
  for_each = local.amr_normalized_environments

  cidr_block = each.value.network.vpc_config.cidr_block

  tags = {
    Name        = "${each.key}-vpc"
    Environment = each.key
  }
}

resource "aws_ecs_cluster" "amr_main" {
  for_each = local.amr_normalized_environments

  name = "${each.key}-cluster"

  tags = {
    Environment = each.key
  }
}

# 1. Complex AWS ECS Service with dynamic configurations
resource "aws_ecs_service" "amr_microservices" {
  for_each = {
    for deployment in local.amr_service_deployments :
    deployment.deployment_key => deployment
    if contains(["web", "api"], deployment.service)
  }

  name          = each.value.deployment_key
  cluster       = aws_ecs_cluster.amr_main[each.value.environment].id
  desired_count = local.amr_env_map[each.value.environment].config.instance_count
  launch_type   = local.amr_env_map[each.value.environment].tier == "premium" ? "FARGATE" : "EC2"

  network_configuration {
    subnets = [
      for subnet_key, subnet in local.amr_normalized_environments[each.value.environment].network.subnet_configs :
      aws_subnet.amr_main["${each.value.environment}-${subnet_key}"].id
    ]
    security_groups  = [aws_security_group.amr_service_sg[each.value.environment].id]
    assign_public_ip = each.value.protocol == "https"
  }

  dynamic "load_balancer" {
    for_each = each.value.protocol == "https" ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.amr_service_tg[each.key].arn
      container_name   = each.value.service
      container_port   = each.value.port
    }
  }

  tags = merge(
    each.value.tags,
    local.amr_monitoring_configs[each.value.environment].metrics_enabled ? {
      "Monitoring"    = "enabled"
      "RetentionDays" = tostring(local.amr_monitoring_configs[each.value.environment].retention_period)
    } : {}
  )

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# 2. Complex Storage Configuration with conditional features
resource "aws_ebs_volume" "amr_storage_volumes" {
  for_each = merge(flatten([
    for env_name, env in local.amr_normalized_environments : [
      for storage_key, storage in env.storage_configs : {
        "${env_name}-${storage_key}" = merge(storage, {
          environment  = env_name
          storage_name = storage_key
        })
      }
    ]
  ])...)

  availability_zone = data.aws_availability_zones.amr_available.names[0]
  size              = each.value.normalized_size
  type              = each.value.type

  dynamic "ebs_block_device" {
    for_each = each.value.performance_tier == "high" ? [1] : []
    content {
      iops        = try(each.value.iops, null)
      throughput  = try(each.value.throughput, null)
      volume_size = each.value.size
      encrypted   = true
      kms_key_id  = try(each.value.encryption.kms_key, null)
    }
  }

  tags = merge(
    try(local.amr_normalized_environments[each.value.environment].config.tags, {}),
    {
      Name            = "${each.value.environment}-${each.value.storage_name}"
      BackupEligible  = tostring(each.value.backup_eligible)
      PerformanceTier = each.value.performance_tier
    }
  )
}

# Create VPC Endpoint for S3 (referenced by security group)
resource "aws_vpc_endpoint" "amr_s3" {
  for_each = local.amr_normalized_environments

  vpc_id       = aws_vpc.amr_main[each.key].id
  service_name = "com.amazonaws.${data.aws_region.amr_current.name}.s3"
}

# 3. Complex Security Group with dynamic rules
resource "aws_security_group" "amr_service_sg" {
  for_each = local.amr_normalized_environments

  name_prefix = "${each.key}-service-sg"
  vpc_id      = aws_vpc.amr_main[each.key].id
  description = "Security group for ${each.key} environment services"

  dynamic "ingress" {
    for_each = each.value.network.security_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      self        = ingress.value.self
      cidr_blocks = length(try(ingress.value.cidr_blocks, [])) > 0 ? ingress.value.cidr_blocks : null
    }
  }

  dynamic "egress" {
    for_each = {
      for subnet_key, subnet in each.value.network.subnet_configs :
      subnet_key => subnet
      if !subnet.public
    }
    content {
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      prefix_list_ids = [aws_vpc_endpoint.amr_s3[each.key].prefix_list_id]
      description     = "Allow outbound traffic to S3 VPC Endpoint for ${egress.key}"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.amr_normalized_environments[each.key].config.tier == "development" ? {
      Environment  = "development"
      DebugEnabled = "true"
      } : {
      Environment = "production"
      Compliance  = "strict"
    },
    {
      ManagedBy = "Terraform"
      Name      = "${each.key}-service-sg"
    }
  )
}

/*

{
  name = "dev"
  tier = "basic"
  config = {
    instance_count = 1
    multi_az = false
  }
}

{
  tier_config = {
    instance_type = "t3.small"
    max_count = 1
    multi_az = false
  }
  services = {
    web = {
      enabled = true
      port_config = [
        {
          number = 80
          protocol = "http"
          priority = "normal"
        },
        {
          number = 443
          protocol = "https"
          priority = "high"
        }
      ]
      settings = {
        cache_ttl = "3600"
        ssl_policy = "TLS1.2"
        environment = "dev"
        tier = "basic"
      }
    }
    api = {
      enabled = false
      # ... other configurations
    }
  }
  tags = {
    environment = "development"
    cost_center = "dev-123"
    ManagedBy = "Terraform"
    Environment = "dev"
    Tier = "basic"
  }
}

[
  {
    deployment_key = "dev-web-80"
    environment = "dev"
    service = "web"
    port = 80
    protocol = "http"
    priority = "normal"
    enabled = true
    settings = {
      cache_ttl = "3600"
      ssl_policy = "TLS1.2"
      environment = "dev"
      tier = "basic"
    }
    tags = {
      environment = "development"
      cost_center = "dev-123"
      ManagedBy = "Terraform"
      Environment = "dev"
      Tier = "basic"
    }
  }
  # ... similar entry for port 443
]

*/