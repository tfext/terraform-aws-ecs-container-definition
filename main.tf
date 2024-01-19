data "aws_region" "current" {}

locals {
  image              = join("/", var.repository == null ? [var.image] : [var.repository, var.image])
  image_tag          = coalesce(var.image_tag, terraform.workspace == "default" ? "latest" : terraform.workspace)
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
      awslogs-region        = coalesce(var.aws_logging.region, "us-west-2")
      awslogs-stream-prefix = local.logging_name
    }
  }

  container_definition = merge(
    {
      name              = var.container_name
      cpu               = var.cpu * 1024
      memoryReservation = var.memory_required
      environment       = local.container_env
      essential         = true
      logConfiguration  = local.logging
      image = join("", [
        local.image,
        "@",
        data.docker_registry_image.image.sha256_digest
      ])
    },
    var.max_memory == null ? {} : { memory = var.max_memory },
    var.command == null ? {} : { command = var.command },
    var.entrypoint == null ? {} : { entrypoint = var.entrypoint },
    local.port_mappings,
    local.mounts
  )
}

# Resolve image and tag
data "docker_registry_image" "image" {
  name = "${local.image}:${local.image_tag}"
}
