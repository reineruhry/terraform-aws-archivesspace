# ArchivesSpace Terraform module

Run ArchivesSpace as an ECS service using an all-inclusive
task definition:

- Nginx for http to https redirects and certbot (optional for SSL certs)
- MySQL cli for creating the database
- Nginx proxy for routing to ArchivesSpace endpoints
- ArchivesSpace with EFS for persistence (`/archivesspace/data`)
- Solr with EFS for persistence (`/var/solr`)

## Usage

See the examples for deployment options:

- [complete: includes all necessary resources](./examples/complete/README.md)
- [services: configures the module using references to pre-existing resources](./examples/services/README.md)

## Notable configuration details

### Custom environment and secrets configuration

Custom (non-predefined) environment and secrets configuration can be defined:

```hcl
custom_env_cfg = {
  "APPCONFIG_BACKEND_LOG_LEVEL" = "info"
}
custom_secrets_cfg = {
  "ASPACE_SECRET_KEY" = "arn:aws:ssm:us-east-2:111222333444:parameter/ASpaceSecretKey"
}
```

### Launch type

To deploy to an ECS/EC2 auto-scaling group:

```ini
capacity_provider        = "EC2"
network_mode             = "bridge"
requires_compatibilities = ["EC2"]
target_type              = "instance"
```

To deploy to an ECS/EC2 auto-scaling group with `awsvpc` network mode:

```ini
capacity_provider        = "EC2"
network_mode             = "awsvpc"
requires_compatibilities = ["EC2"]
target_type              = "ip"
```

To deploy to Fargate (the default):

```ini
capacity_provider        = "FARGATE"
network_mode             = "awsvpc"
requires_compatibilities = ["FARGATE"]
target_type              = "ip"
```

### Listeners

The module requires `http_listener_arn` for nginx to redirect http
requests to https. The latter container includes certbot for (optionally)
generating SSL certificates. The latter use case accounts for why
the http redirection is happening within a container rather than as
a listener rule.

The `https_listener_arn` routes traffic to ArchivesSpace.

### Resource allocations

#### Cpu

This only applies to Fargate containers.

```hcl
cpu = 1024 # 1 v/cpu default
```

#### Memory

```hcl
app_memory  = 2048 # specific allocation to the aspace container
solr_memory = 1024 # specific allocation to the solr container
```

The task definition memory is set to (app_memory + solr_memory). When
running on Fargate this needs to equal a [compatible value](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html).
