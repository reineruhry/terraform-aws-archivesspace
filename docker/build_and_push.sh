#!/bin/bash

docker compose build
docker tag docker-aspace-proxy lyrasis/aspace-proxy:latest
docker push lyrasis/aspace-proxy:latest
