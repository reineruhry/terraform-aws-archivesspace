#!/bin/bash

docker compose build
docker tag docker-aspace-proxy lyrasis/aspace-proxy:latest
docker push lyrasis/aspace-proxy:latest

if [ -z "$ASPACE_PROXY_ECR_IMG" ] ; then
  echo "ASPACE_PROXY_ECR_IMG not set, skipping push to ECR"
  exit 0
fi

docker tag docker-aspace-proxy $ASPACE_PROXY_ECR_IMG
docker push $ASPACE_PROXY_ECR_IMG
