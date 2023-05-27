locals {
  data_volume       = "${var.name}-data"
  hostnames         = toset([var.public_hostname, var.staff_hostname])
  listener_priority = var.listener_priority * 10 # create gaps in sequence for targets
  public_url        = "https://${var.public_hostname}${var.public_prefix}"
  solr_url          = "http://${var.capacity_provider == "FARGATE" ? "localhost" : "solr"}:8983/solr/archivesspace"
  staff_url         = "https://${var.staff_hostname}${var.staff_prefix}"

  targets = {
    certbot = {
      arn      = var.http_listener_arn
      hosts    = local.hostnames
      health   = "/health"
      paths    = ["*"]
      port     = 80
      priority = local.listener_priority
    }
  }

  task_config = {
    app_img            = var.app_img
    app_memory         = var.memory - var.solr_memory
    certbot_alb_name   = var.certbot_alb_name
    certbot_domains    = join(",", tolist(local.hostnames))
    certbot_email      = var.certbot_email
    certbot_enabled    = var.certbot_enabled ? "true" : "false"
    custom_env_cfg     = var.custom_env_cfg
    custom_secrets_cfg = var.custom_secrets_cfg
    # TODO convert this into a param
    db_url             = "jdbc:mysql://${var.db_host}:3306/${var.db_name}?useUnicode=true&characterEncoding=UTF-8&user=${data.aws_ssm_parameter.db_username.value}&password=${data.aws_ssm_parameter.db_password.value}&useSSL=false&allowPublicKeyRetrieval=true"
    initialize_plugins = var.initialize_plugins
    log_group          = var.log_group
    name               = var.name
    network_mode       = var.network_mode
    region             = data.aws_region.current.name
    solr_img           = var.solr_img
    solr_memory        = var.solr_memory
    solr_url           = local.solr_url
    timezone           = var.timezone
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  network_mode             = var.network_mode
  requires_compatibilities = var.requires_compatibilities
  cpu                      = var.capacity_provider == "FARGATE" ? var.cpu : null
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.this.arn
  task_role_arn            = aws_iam_role.this.arn

  container_definitions = templatefile("${path.module}/task-definition/archivesspace.json.tpl", local.task_config)

  # volume {
  #   name = local.data_volume

  #   efs_volume_configuration {
  #     file_system_id     = var.efs_id
  #     transit_encryption = "ENABLED"

  #     authorization_config {
  #       access_point_id = aws_efs_access_point.data.id
  #     }
  #   }
  # }
}

resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.instances

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  enable_execute_command = true

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider
    weight            = 100
  }

  dynamic "load_balancer" {
    for_each = local.targets
    content {
      container_name   = load_balancer.key
      container_port   = load_balancer.value.port
      target_group_arn = aws_lb_target_group.this[load_balancer.key].arn
    }
  }

  dynamic "network_configuration" {
    for_each = var.network_mode == "awsvpc" ? ["true"] : []
    content {
      assign_public_ip = var.assign_public_ip
      security_groups  = [var.security_group_id]
      subnets          = var.subnets
    }
  }
}

resource "aws_efs_access_point" "data" {
  file_system_id = var.efs_id

  root_directory {
    path = "/${local.data_volume}"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }
}
