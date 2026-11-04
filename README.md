ecs_container_definition
========================

Common logic for creating ECS container definitions with app config

Variables
---------

| Name              | Type   | Required? | Description                                                                                                                 |
|-------------------|--------|-----------|-----------------------------------------------------------------------------------------------------------------------------|
| `name`            | string | Y         | Service name (e.g. `my-service`)                                                                                            |
| `image`           | string | Y         | Docker image name                                                                                                           |
| `image_tag`       | string | N         | Docker image tag (default is current environment)                                                                           |
| `pin_digest`      | bool   | N         | Pin the image to the tag's current digest, looked up with the Docker provider (default is true). Set false to reference the tag itself (`<repository>/<image>:<tag>`), with no lookup |
| `secrets`         | object | N         | Secrets Manager JSON secret to expose as environment variables (default is none). See [Secrets](#secrets)                   |
| `aws_logging`     | object | N         | `{ group, region }`: log to CloudWatch instead of Fluentd. `region` defaults to the provider's region                        |
| `memory_required` | number | N         | Memory capacity to reserve for scaling in MB (default is 128)                                                               |
| `port`            | string | N         | Inbound port to expose for service APIs (default is none)                                                                   |
| `rails`           | bool   | N         | Set to true for Ruby on Rails services                                                                                      |
| `shared_cache`    | bool   | N         | Set to true for Rails services that are [MemCache enabled](https://bitbucket.org/didjatv/didja_rails/src/master/README.md). |

Outputs
-------
| Name              | Type   | Description                                                                           |
|-------------------|--------|---------------------------------------------------------------------------------------|
| `result`          | string | Rendered ECS container definition. This can be used to create a full Task Definition. |
| `task_definition` | string | Full ECS task definition. Use this if no need to combine with other containers.       |
| `port`            | string | Container port as given by the `port` variable.                                       |
| `container_name`  | string | Container name as given by the `name` variable.                                       |
| `secrets`         | object | The `secrets` input, passed through so another definition can reuse the mapping.      |
| `secret_arns`     | list   | ARNs of the secrets the definition reads, for the service's execution role.           |

Secrets
-------

`secrets.arn` is a Secrets Manager secret holding a JSON object, and `secrets.vars` maps each
environment variable to a key in it. Each entry becomes
`{ name = <var>, valueFrom = "<arn>:<key>::" }` in the definition's `secrets`.

```
module "container" {
  ...
  secrets = {
    arn  = aws_secretsmanager_secret.app.arn
    vars = { DATABASE_URL = "database_url" }
  }
}
```

The task needs an execution role that can read the secret. `terraform-aws-ecs-service`
creates one when given this module's output.
