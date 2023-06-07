# ArchivesSpace Terraform module

Run ArchivesSpace as an ECS service using an all-inclusive
task definition:

- Nginx for http to https redirects and certbot
- MySQL cli for creating the database
- ArchivesSpace with EFS for persistence (`/archivesspace/data`)
- Solr with EFS for persistence (`/var/solr`)

## Configuration

### Launch type

To deploy to an ECS/EC2 auto-scaling group:

```hcl
capacity_provider        = "EC2"
network_mode             = "bridge"
requires_compatibilities = ["EC2"]
target_type              = "instance"
```

To deploy to Fargate (the default):

```hcl
capacity_provider        = "FARGATE"
network_mode             = "awsvpc"
requires_compatibilities = ["FARGATE"]
target_type              = "ip"
```
