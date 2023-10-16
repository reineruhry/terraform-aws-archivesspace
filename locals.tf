locals {
  api_ips_allowed          = join("; ", formatlist("allow %s", var.app_api_ips_allowed))
  api_prefix               = local.staff_prefix != "/" ? "${local.staff_prefix}/api/" : "/api/"
  app_efs_id               = var.app_efs_id
  app_img                  = var.app_img
  app_memory               = var.app_memory
  assign_public_ip         = var.assign_public_ip
  capacity_provider        = var.capacity_provider
  certbot_alb_name         = var.certbot_alb_name
  certbot_domains          = join(",", tolist(local.hostnames))
  certbot_email            = var.certbot_email
  certbot_enabled          = var.certbot_enabled ? "true" : "false"
  certbot_img              = "lyrasis/certbot-acm:latest" # TODO: var
  certbot_port             = 80
  cluster_id               = var.cluster_id
  cpu                      = var.cpu
  custom_env_cfg           = var.custom_env_cfg
  custom_secrets_cfg       = var.custom_secrets_cfg
  data_volume              = "${local.name}-data"
  db_host                  = var.db_host
  db_migrate               = local.instances == 1 ? true : false
  db_name                  = var.db_name
  db_password              = data.aws_ssm_parameter.db_password.value
  db_password_param        = var.db_password_param
  db_username              = data.aws_ssm_parameter.db_username.value
  db_username_param        = var.db_username_param
  db_url                   = "jdbc:mysql://${local.db_host}:3306/${local.db_name}?useUnicode=true&characterEncoding=UTF-8&user=${local.db_username}&password=${local.db_password}&useSSL=false&allowPublicKeyRetrieval=true"
  hostnames                = toset([local.public_hostname, local.staff_hostname])
  http_listener_arn        = var.http_listener_arn
  https_listener_arn       = var.https_listener_arn
  initialize_plugins       = var.initialize_plugins
  instances                = var.instances
  java_opts                = var.java_opts
  memory                   = var.task_memory
  name                     = var.name
  network_mode             = var.network_mode
  oai_prefix               = local.public_prefix != "/" ? "${local.public_prefix}oai" : "/oai"
  proxy_img                = "lyrasis/aspace-proxy:latest" # TODO: var
  proxy_port               = 4000
  proxy_type               = local.public_hostname == local.staff_hostname ? "single" : "multi"
  public_hostname          = var.public_hostname
  public_prefix            = var.public_prefix
  public_url               = "https://${local.public_hostname}${local.public_prefix}"
  pui_ips_allowed          = join("; ", formatlist("allow %s", var.app_pui_ips_allowed))
  real_ip_cidr             = "10.0.0.0/16" # TODO: var
  requires_compatibilities = var.requires_compatibilities
  security_group_id        = var.security_group_id
  solr_efs_id              = var.solr_efs_id
  solr_img                 = var.solr_img
  solr_memory              = var.solr_memory
  solr_url                 = "http://${local.network_mode == "awsvpc" ? "localhost" : "solr"}:8983/solr/archivesspace"
  solr_volume              = "${local.name}-solr"
  staff_hostname           = var.staff_hostname
  staff_prefix             = var.staff_prefix != "/" ? trimsuffix(var.staff_prefix, "/") : var.staff_prefix
  staff_url                = "https://${local.staff_hostname}${local.staff_prefix}"
  subnets                  = var.subnets
  tags                     = var.tags
  target_type              = var.target_type
  task_memory              = var.task_memory
  timezone                 = var.timezone
  upstream_host            = local.network_mode == "awsvpc" ? "localhost" : "app"
  vpc_id                   = var.vpc_id

  task_config = {
    api_ips_allowed    = local.api_ips_allowed
    api_prefix         = local.api_prefix
    app_data           = local.data_volume
    app_img            = local.app_img
    app_memory         = local.app_memory
    certbot_alb_name   = local.certbot_alb_name
    certbot_domains    = local.certbot_domains
    certbot_email      = local.certbot_email
    certbot_enabled    = local.certbot_enabled
    certbot_img        = local.certbot_img
    certbot_port       = local.certbot_port
    custom_env_cfg     = local.custom_env_cfg
    custom_secrets_cfg = local.custom_secrets_cfg
    db_host            = local.db_host
    db_migrate         = local.db_migrate
    db_name            = local.db_name
    db_password_arn    = data.aws_ssm_parameter.db_password.arn
    db_url             = aws_ssm_parameter.db-url.arn
    db_user            = data.aws_ssm_parameter.db_username.value
    initialize_plugins = local.initialize_plugins
    java_opts          = local.java_opts
    log_group          = aws_cloudwatch_log_group.this.name
    name               = local.name
    network_mode       = local.network_mode
    oai_prefix         = local.oai_prefix
    proxy_img          = local.proxy_img
    proxy_port         = local.proxy_port
    proxy_type         = local.proxy_type
    public_hostname    = local.public_hostname
    public_prefix      = local.public_prefix
    public_url         = local.public_url
    pui_ips_allowed    = local.pui_ips_allowed
    real_ip_cidr       = local.real_ip_cidr
    region             = data.aws_region.current.name
    secret_key         = random_password.secret_key.result
    solr_data          = local.solr_volume
    solr_img           = local.solr_img
    solr_memory        = local.solr_memory
    solr_url           = local.solr_url
    staff_hostname     = local.staff_hostname
    staff_prefix       = local.staff_prefix
    staff_url          = local.staff_url
    timezone           = local.timezone
    upstream_host      = local.upstream_host
  }

  # setup routes for load balancer
  targets = {
    certbot = {
      container = "certbot"
      arn       = local.http_listener_arn
      hosts     = local.hostnames
      health    = "/health"
      paths     = ["*"]
      port      = local.certbot_port
      prefix    = "certs"
    }
    proxy = {
      container = "proxy"
      arn       = local.https_listener_arn
      hosts     = local.hostnames
      health    = "/health"
      paths     = ["*"]
      port      = local.proxy_port
      prefix    = "proxy"
    }
  }
}
