[
  {
    "name": "solr",
    "image": "${img}",
    "networkMode": "${network_mode}",
    "essential": true,
    "command": [
      "/bin/bash",
      "-c",
      "${join(" ", [
        "cp /opt/solr/server/solr/configsets/archivesspace/conf/* /var/solr/data/archivesspace/conf/;",
        "rm -f /var/solr/data/archivesspace/data/index/write.lock;",
        "solr-create -p 8983 -c archivesspace -d archivesspace"
      ])}"
    ],
    "environment": [
      {
        "name": "SOLR_JAVA_MEM",
        "value": "-Xms${memory}m -Xmx${memory}m"
      },
      {
        "name": "SOLR_OPTS",
        "value": "-Dsolr.lock.type=${lock_type}"
      }
    ],
    "portMappings": [
      {
        "containerPort": ${port}
      }
    ],
    "mountPoints": [
      {
        "sourceVolume": "${data}",
        "containerPath": "/var/solr"
      }
    ],
    "ulimits": [
      {
        "name": "nofile",
        "softLimit": 65000,
        "hardLimit": 65000
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "archivesspace"
      }
    }
  }
]
