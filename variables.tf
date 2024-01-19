variable "name" {
  type        = string
  description = "Name of service"
}

variable "container_name" {
  type        = string
  default     = "app"
  description = "Name of the container within the task definition (set if multiple containers)"
}

variable "repository" {
  type        = string
  default     = null
  description = "Custom docker repository. Defaults to Dockerhub"
}

variable "image" {
  type        = string
  description = "Name of docker image (do not include nexus or tags)"
}

variable "image_tag" {
  type        = string
  default     = null
  description = "Image tag to use (default is environment or latest)"
}

variable "command" {
  type        = list(string)
  default     = null
  description = "Optional command for running Docker image"
}

variable "entrypoint" {
  type        = list(string)
  default     = null
  description = "Optional entrypoint override"
}

variable "cpu" {
  type        = number
  default     = 0.25
  description = "Number of vCPUs for the container"
}

variable "memory_required" {
  type        = number
  default     = 128
  description = "Memory (MB) that should be reserved per container. This will affect host allocation and scaling."
}

variable "max_memory" {
  type    = number
  default = null
}

variable "service_type" {
  type        = string
  default     = "http"
  description = "Must be http or udp"
  validation {
    condition     = contains(["http", "udp"], var.service_type)
    error_message = "Invalid service type"
  }
}

variable "port" {
  type        = number
  default     = null
  description = "Service port if the container exposes an API"
}

variable "ports" {
  type = list(object({
    port        = number
    host_port   = optional(number)
    public_port = optional(number)
    protocol    = optional(string)
    health_check = optional(object({
      enabled      = optional(bool)
      path         = optional(string)
      status_codes = optional(string)
      threshold    = optional(number)
      interval     = optional(number)
      timeout      = optional(number)
    }))
  }))
  default     = null
  description = "Advanced port definitions. Mutually exclusive with 'port'"
}

variable "environment" {
  type        = map(string)
  default     = {}
  description = "Provide custom environment variables"
}

variable "shared_data" {
  type = object({
    efs_id          = string
    access_point_id = string
    mount_path      = string
  })
  default     = null
  description = "Mount an EFS folder in the container. Default EFS path is /shared-data/<name>."
}

variable "aws_logging" {
  type = object({
    group  = string
    region = optional(string)
  })
  default     = null
  description = "Set config to use AWS CloudWatch logging instead of the default Fluent aggregation"
}
