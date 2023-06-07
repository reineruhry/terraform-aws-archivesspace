locals {
  data_volume       = "${var.name}-data"
  db_url            = "jdbc:mysql://${var.db_host}:3306/${var.db_name}?useUnicode=true&characterEncoding=UTF-8&user=${data.aws_ssm_parameter.db_username.value}&password=${data.aws_ssm_parameter.db_password.value}&useSSL=false&allowPublicKeyRetrieval=true"
  hostnames         = toset([var.public_hostname, var.staff_hostname])
  listener_priority = var.listener_priority * 10 # create gaps in sequence for targets
  public_url        = "https://${var.public_hostname}${var.public_prefix}"
  solr_url          = "http://${var.capacity_provider == "FARGATE" ? "localhost" : "solr"}:8983/solr/archivesspace"
  solr_volume       = "${var.name}-solr"
  staff_url         = "https://${var.staff_hostname}${var.staff_prefix}"

  task_config = {
    app_data           = local.data_volume
    app_img            = var.app_img
    app_memory         = var.memory - var.solr_memory
    certbot_alb_name   = var.certbot_alb_name
    certbot_domains    = join(",", tolist(local.hostnames))
    certbot_email      = var.certbot_email
    certbot_enabled    = var.certbot_enabled ? "true" : "false"
    custom_env_cfg     = var.custom_env_cfg
    custom_secrets_cfg = var.custom_secrets_cfg
    db_host            = var.db_host
    db_name            = var.db_name
    db_password_arn    = data.aws_ssm_parameter.db_password.arn
    db_url             = aws_ssm_parameter.db-url.arn
    db_user            = data.aws_ssm_parameter.db_username.value
    initialize_plugins = var.initialize_plugins
    log_group          = var.log_group
    name               = var.name
    network_mode       = var.network_mode
    public_url         = local.public_url
    region             = data.aws_region.current.name
    solr_data          = local.solr_volume
    solr_img           = var.solr_img
    solr_memory        = var.solr_memory
    solr_url           = local.solr_url
    staff_url          = local.staff_url
    timezone           = var.timezone
  }

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
    # proxy = {
    #   container = "proxy"
    #   arn       = var.https_listener_arn
    #   hosts     = local.hostnames
    #   health    = "${staff_prefix}api/version"
    #   paths     = ["*"]
    #   port      = 80
    #   priority  = local.listener_priority + 1
    # }
  }
}
