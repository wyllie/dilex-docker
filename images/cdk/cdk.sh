#!/bin/bash

usage() {
  echo "Usage: cdk.sh <cdk-command>"
  echo "Example: cdk.sh deploy"
  exit 1
}

# Check if an argument is passed (e.g., cdk deploy, cdk synth, etc.)
if [ -z "$1" ]; then
  usage
fi

# Define the image name (make sure the Dockerfile is built and tagged with this name)
IMAGE_NAME="wyllie/aws-cdk-alpine:latest"


# Run the Docker container with the current directory mounted and .aws credentials mounted
docker run -it --rm \
  -v $(pwd):/app \
  -v ~/.aws:/root/.aws \
  -w /app \
  $IMAGE_NAME cdk "$@"
