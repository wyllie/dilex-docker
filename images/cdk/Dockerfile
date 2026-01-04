# wyllie/cdk
# AWS CDK deployment image (Node + AWS CLI v2)

FROM wyllie/ci-base:alpine3.23.2-1

# Install core tooling: Node.js, npm, and AWS CLI v2
RUN apk add --no-cache \
      nodejs \
      npm \
      aws-cli

# Install AWS CDK globally
RUN npm install -g aws-cdk

WORKDIR /work

CMD ["/bin/bash"]
