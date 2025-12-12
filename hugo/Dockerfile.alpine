# Use the official Alpine base image
FROM alpine:latest

# Install necessary packages: bash, Hugo, AWS CLI, Node.js, npm, git, etc.
RUN apk update && \
    apk add --no-cache bash curl git python3 py3-pip nodejs npm go hugo wget

# Install the AWS CLI - this can't be installed with apk and needs it's own venv
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip
RUN /opt/venv/bin/pip install awscli --upgrade

# Add a few directories to the path 
ENV PATH="/usr/local/go/bin:/opt/venv/bin:/usr/local/bin:$PATH"

# Set the working directory inside the container
WORKDIR /app

# Set the default command to run bash
CMD ["/bin/bash"]
