[
  {
    "name": "certbot",
    "image": "lyrasis/certbot-acm:latest",
    "networkMode": "${network_mode}",
    "essential": true,
    "environment": [
      {
        "name": "CERTBOT_ALB_NAME",
        "value": "${certbot_alb_name}"
      },
      {
        "name": "CERTBOT_DOMAINS",
        "value": "${certbot_domains}"
      },
      {
        "name": "CERTBOT_EMAIL",
        "value": "${certbot_email}"
      },
      {
        "name": "CERTBOT_ENABLED",
        "value": "${certbot_enabled}"
      }
    ],
    "portMappings": [
      {
        "containerPort": 80
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "${name}"
      }
    }
  },
  {
    "name"  : "createdb",
    "image" : "mysql:8",
    "networkMode": "${network_mode}",
    "essential": false,
    "command" : [
      "/bin/sh",
      "-c",
      "mysql --user ${db_user} -e \"CREATE DATABASE IF NOT EXISTS ${db_name} default character set utf8mb4;\""
    ],
    "environment": [
      {
        "name" : "MYSQL_HOST",
        "value" : "${db_host}"
      }
    ],
    "secrets": [
      {
        "name" : "MYSQL_PWD",
        "valueFrom" : "${db_password_arn}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "${name}"
      }
    }
  },
  {
    "name": "solr",
    "image": "${solr_img}",
    "networkMode": "${network_mode}",
    "essential": true,
    "command": ["solr-create", "-p", "8983", "-c", "archivesspace", "-d", "archivesspace"],
    "environment": [
      {
        "name": "SOLR_JAVA_MEM",
        "value": "-Xms${solr_memory}m -Xmx${solr_memory}m"
      }
    ],
    "mountPoints": [
      {
        "sourceVolume": "${solr_data}",
        "containerPath": "/var/solr"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "${name}"
      }
    }
  }
]
