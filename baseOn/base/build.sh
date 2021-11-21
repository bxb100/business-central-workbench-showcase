#!/bin/bash

# *************************************************************
# jJBoss Business-Central Workbench - Docker image build script
# *************************************************************

IMAGE_NAME="bxb100/jboss-base"
IMAGE_TAG="1.0.0"


# Build the container image.
echo "Building the Docker container for $IMAGE_NAME:$IMAGE_TAG.."
docker build --rm -t $IMAGE_NAME:latest -t $IMAGE_NAME:$IMAGE_TAG .
echo "Build done"