# ArchivesSpace

Configuration in this directory creates an ArchivesSpace deployment
using pre-existing service dependencies (vpc, db, alb etc.).

## Usage

To run this example you need to create `terraform.tfvars`:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Update the values as appropriate:

```bash
archivesspace_img   = "archivesspace/archivesspace:3.3.1"
cluster_name        = "aspace-cluster"
db_host             = "database.archivesspace.org"
db_name             = "archivesspace"
db_password_param   = "aspace-db-password"
db_username_param   = "aspace-db-username"
efs_name            = "aspace-efs"
domain              = "archivesspace.org"
lb_name             = "aspace-lb"
profile             = "default"
profile_for_dns     = "default"
security_group_name = "aspace-private-app"
solr_img            = "archivesspace/solr:3.3.1"
subnet_type         = "Private"
vpc_name            = "aspace-vpc"
```

The key ones are:

- `cluster_name`
  - the name of an existing ECS cluster
- `db_*`
  - valid db parameters, including existing SSM param names
- `domain`
  - this is the domain to use for public DNS
  - you must have a Route53 hosted zone available for this domain
- `efs_name`
  - the name of an existing EFS
- `lb_name`
  - the name of an existing ALB
- `profile_for_dns`
  - set to a different profile if necessary
  - this profile should contain the hosted zone for `domain`
- `security_group_name`
  - the name of an existing security group
- `subnet_type`
  - the type (by tag) of existing subnets
- `vpc_name`
  - the name of an existing vpc

Then execute:

```bash
terraform init
terraform plan
terraform apply
```

Note that this example creates resources which cost money. Run terraform destroy
when you don't need these resources.
