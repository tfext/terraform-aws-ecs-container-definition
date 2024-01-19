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
