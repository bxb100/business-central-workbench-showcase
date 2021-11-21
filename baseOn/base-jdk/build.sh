#!/bin/bash

# *************************************************************
# jJBoss Business-Central Workbench - Docker image build script
# *************************************************************

IMAGE_NAME="bxb100/jboss-base-jdk"
IMAGE_TAG="11"


# Build the container image.
echo "Building the Docker container for $IMAGE_NAME:$IMAGE_TAG.."
docker build --rm -t $IMAGE_NAME:$IMAGE_TAG .
echo "Build done"