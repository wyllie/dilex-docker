# wyllie/cdk
# AWS CDK deployment image (Node + AWS CLI v2)

FROM wyllie/aws-cli:awscli2.32.7-alpine3.23.2-1

ARG CDK_VER=2.1100.3

# Install core tooling: Node.js, npm, and AWS CLI v2
RUN apk add --no-cache \
      nodejs \
      npm  \
      && npm install -g aws-cdk@{CDK_VER}

WORKDIR /work

CMD ["/bin/bash"]
