resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  network_mode             = var.network_mode
  requires_compatibilities = var.requires_compatibilities
  cpu                      = var.capacity_provider == "FARGATE" ? var.cpu : null
  memory                   = local.memory
  execution_role_arn       = aws_iam_role.this.arn
  task_role_arn            = aws_iam_role.this.arn

  container_definitions = templatefile("${path.module}/task-definition/archivesspace.json.tpl", local.task_config)

  volume {
    name = local.data_volume

    efs_volume_configuration {
      file_system_id     = var.app_efs_id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.data.id
      }
    }
  }

  volume {
    name = local.solr_volume

    efs_volume_configuration {
      file_system_id     = var.solr_efs_id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.solr.id
      }
    }
  }
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
      container_name   = load_balancer.value.container
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

  tags = var.tags
}

resource "aws_efs_access_point" "data" {
  file_system_id = var.app_efs_id

  root_directory {
    path = "/${local.data_volume}"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }
}

resource "aws_efs_access_point" "solr" {
  file_system_id = var.solr_efs_id

  root_directory {
    path = "/${local.solr_volume}"
    creation_info {
      owner_gid   = 8983
      owner_uid   = 8983
      permissions = "755"
    }
  }
}

resource "aws_ssm_parameter" "db-url" {
  name  = "${var.name}-db-url"
  type  = "SecureString"
  value = local.db_url
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/ecs/${var.name}"
  retention_in_days = 7
}
