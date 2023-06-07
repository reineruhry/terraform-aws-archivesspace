locals {
  data_volume       = "${var.name}-data"
  hostnames         = toset([var.public_hostname, var.staff_hostname])
  listener_priority = var.listener_priority * 10 # create gaps in sequence for targets
  public_url        = "https://${var.public_hostname}${var.public_prefix}"
  solr_url          = "http://${var.capacity_provider == "FARGATE" ? "localhost" : "solr"}:8983/solr/archivesspace"
  solr_volume       = "${var.name}-solr"
  staff_url         = "https://${var.staff_hostname}${var.staff_prefix}"

  # setup routes for load balancer
  targets = {
    certbot = {
      container = "certbot"
      arn       = var.http_listener_arn
      hosts     = local.hostnames
      health    = "/health"
      paths     = ["*"]
      port      = 80
      priority  = local.listener_priority
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
    db_url             = aws_ssm_parameter.db-url.arn
    initialize_plugins = var.initialize_plugins
    log_group          = var.log_group
    name               = var.name
    network_mode       = var.network_mode
    region             = data.aws_region.current.name
    solr_data          = local.solr_volume
    solr_img           = var.solr_img
    solr_memory        = var.solr_memory
    solr_url           = local.solr_url
    timezone           = var.timezone
  }
}
