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
  }
]
