variable "certificate_domain" {
  default = "*.lyrasistechnology.org"
}

variable "domain" {
  default = "lyrasistechnology.org"
}

variable "arclight_img" {
  default = "lyrasis/arclight"
}

variable "profile" {
  default = "default"
}

variable "profile_for_dns" {
  default = "default"
}

variable "solr_img" {
  default = "lyrasis/arclight-solr"
}

provider "aws" {
  region  = local.region
  profile = var.profile
}

provider "aws" {
  region  = local.region
  profile = var.profile_for_dns
  alias   = "dns"
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}
data "aws_acm_certificate" "issued" {
  domain   = var.certificate_domain
  statuses = ["ISSUED"]
}
data "aws_route53_zone" "selected" {
  provider = aws.dns
  name     = "${var.domain}."
}

data "aws_iam_role" "ecs_task_role" {
  name = local.iam_ecs_task_role_arn
}

locals {
  name    = "archivesspace-ex-${basename(path.cwd)}"
  region  = "us-west-2"
  service = "ex-complete"

  iam_ecs_task_role_arn  = "aspace-dcsp-production-ECSTaskRole"
  vpc_cidr               = "10.99.0.0/18"
  azs                    = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/dts-hosting/terraform-aws-archivesspace"
  }
}

################################################################################
# DSpace resources
################################################################################

module "solr" {
  source = "github.com/dts-hosting/terraform-aws-dspace//modules/solr"

  cluster_id            = module.ecs.cluster_id
  efs_id                = module.efs.id
  iam_ecs_task_role_arn = data.aws_iam_role.ecs_task_role.arn
  img                   = var.solr_img
  name                  = "${local.name}-arclight-solr"
  security_group_id     = module.arclight_sg.security_group_id
  service_discovery_id  = aws_service_discovery_private_dns_namespace.this.id
  subnets               = module.vpc.private_subnets
  vpc_id                = module.vpc.vpc_id
  cmd_args              = ["cp /opt/solr/server/solr/configsets/arclight/conf/* /var/solr/data/arclight/conf/;",
                           "/opt/docker-solr/scripts/solr-create -p 8983 -c arclight -d arclight || true;",
                           "/opt/solr/docker/scripts/solr-create -p 8983 -c arclight -d arclight || true"] 
}

module "arclight" {
  source = "../../modules/arclight"
  
  arclight_url          = "arclight.lyrasistechnology.org"
  cluster_id            = module.ecs.cluster_id
  iam_ecs_task_role_arn = data.aws_iam_role.ecs_task_role.arn
  img                   = var.arclight_img
  listener_arn          = module.alb.listeners["https"].arn
  listener_priority     = 1
  name                  = "${local.name}-arclight"
  security_group_id     = module.arclight_sg.security_group_id
  solr_url              = "http://${local.name}-solr.dspace.solr:8983/solr"
  subnets               = module.vpc.private_subnets
  timezone              = "America/New_York"
  vpc_id                = module.vpc.vpc_id
}

################################################################################
# Supporting resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.14.0"

  name = local.name
  cidr = local.vpc_cidr

  azs              = local.azs
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 3)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 6)]

  create_database_subnet_group = true
  enable_dns_hostnames         = true
  enable_dns_support           = true
  enable_nat_gateway           = true
  map_public_ip_on_launch      = false
  single_nat_gateway           = true

  tags = local.tags
}

module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  name        = "${local.name}-alb"
  description = "ALB security group"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = local.tags
}

module "arclight_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  name        = "${local.name}-arclight"
  description = "Complete DSpace example security group"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      description = "EFS access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      description = "Arclight access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 8983
      to_port     = 8983
      protocol    = "tcp"
      description = "Solr access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = local.tags
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.12.0"

  name               = local.name
  load_balancer_type = "application"

  vpc_id                = module.vpc.vpc_id
  subnets               = module.vpc.public_subnets
  security_groups       = [module.alb_sg.security_group_id]
  create_security_group = false

  listeners = {
    http = {
      action_type = "redirect"
      port        = 80
      protocol    = "HTTP"

      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    https = {
      action_type     = "fixed-response"
      certificate_arn = data.aws_acm_certificate.issued.arn
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-2016-08"

      fixed_response = {
        content_type = "text/plain"
        message_body = "Nothing to see here!"
        status_code  = "200"
      }
    }
  }

  tags = local.tags
}

module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "1.6.4"

  # File system
  name      = local.name
  encrypted = true

  lifecycle_policy = {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  # File system policy
  attach_policy                      = true
  bypass_policy_lockout_safety_check = false
  deny_nonsecure_transport           = false

  policy_statements = [
    {
      sid     = "ClientMount"
      actions = ["elasticfilesystem:ClientMount"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
    },
    {
      sid     = "ClientRootAccess"
      actions = ["elasticfilesystem:ClientRootAccess"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
    },
    {
      sid     = "ClientWrite"
      actions = ["elasticfilesystem:ClientWrite"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
    }
  ]

  # Mount targets / security group
  mount_targets              = { for k, v in zipmap(local.azs, module.vpc.private_subnets) : k => { subnet_id = v } }
  security_group_description = "EFS security group"
  security_group_vpc_id      = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      description = "NFS ingress from VPC"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks
    }
  }

  tags = local.tags
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.11.4"

  cluster_name = local.name

  # Capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  tags = local.tags
}

resource "aws_route53_record" "this" {
  provider = aws.dns

  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${local.name}.${var.domain}"
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_service_discovery_private_dns_namespace" "this" {
  name = "arclight.solr"
  vpc  = module.vpc.vpc_id
}
