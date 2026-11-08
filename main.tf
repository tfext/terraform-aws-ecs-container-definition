data "aws_region" "current" {}

locals {
  image              = join("/", var.repository == null ? [var.image] : [var.repository, var.image])
  image_tag          = coalesce(var.image_tag, terraform.workspace == "default" ? "latest" : terraform.workspace)
  ecr                = can(regex("\\.dkr\\.ecr\\.[^.]+\\.amazonaws\\.com$", coalesce(var.repository, "-")))
  shared_data_volume = "${var.name}-sharedData"

  # User provided environment variables
  user_env = [
    for name, value in var.environment :
    { name = name, value = value }
  ]

  # Resolve and render task definition environment variables
  container_env = concat(
    local.user_env
  )

  # Container port config
  ports = concat(
    var.port != null ? [{
      port         = var.port
      host_port    = null
      public_port  = null
      health_check = null
    }] : [],
    coalesce(var.ports, [])
  )
  port_protocol = var.service_type == "udp" ? "udp" : "tcp"
  port_mappings = local.ports == null ? {} : {
    portMappings = [
      for pm in local.ports : {
        containerPort = pm.port
        hostPort      = coalesce(pm.host_port, 0)
        protocol      = local.port_protocol
      }
    ]
  }

  # Container volume config
  mounts = var.shared_data == null ? {} : {
    mountPoints = [{
      sourceVolume  = local.shared_data_volume,
      containerPath = var.shared_data.mount_path
    }]
  }

  # Container logging config
  logging_name = replace(var.name, "/[-_]+/", "-")
  fluentbit_logging = {
    logDriver = "fluentd"
    options = {
      fluentd-async-connect = "true"
      fluentd-address       = "127.0.0.1:24224"
      tag                   = local.logging_name
    }
  }
  logging = var.aws_logging == null ? local.fluentbit_logging : {
    logDriver = "awslogs"
    options = {
      awslogs-group         = var.aws_logging.group
      awslogs-region        = coalesce(var.aws_logging.region, data.aws_region.current.region)
      awslogs-stream-prefix = local.logging_name
    }
  }

  # Image reference: pinned to the tag's current digest, or the tag itself
  image_digest    = !var.pin_digest ? null : local.ecr ? data.aws_ecr_image.image[0].image_digest : data.docker_registry_image.image[0].sha256_digest
  image_reference = var.pin_digest ? "${local.image}@${local.image_digest}" : "${local.image}:${local.image_tag}"

  # Secrets Manager values exposed as environment variables
  secrets = var.secrets == null ? {} : {
    secrets = [
      for name, key in var.secrets.vars :
      { name = name, valueFrom = "${var.secrets.arn}:${key}::" }
    ]
  }

  container_definition = merge(
    {
      name              = var.container_name
      cpu               = var.cpu * 1024
      memoryReservation = var.memory_required
      environment       = local.container_env
      essential         = true
      logConfiguration  = local.logging
      image             = local.image_reference
    },
    var.max_memory == null ? {} : { memory = var.max_memory },
    var.command == null ? {} : { command = var.command },
    var.entrypoint == null ? {} : { entrypoint = var.entrypoint },
    local.port_mappings,
    local.mounts,
    local.secrets
  )
}

# Resolve image and tag: ECR repositories through the AWS provider, others
# through the Docker provider
data "aws_ecr_image" "image" {
  count           = var.pin_digest && local.ecr ? 1 : 0
  repository_name = var.image
  image_tag       = local.image_tag
}

data "docker_registry_image" "image" {
  count = var.pin_digest && !local.ecr ? 1 : 0
  name  = "${local.image}:${local.image_tag}"
}
