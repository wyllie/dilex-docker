# wyllie/cdk
# AWS CDK deployment image (Node + AWS CLI v2)

FROM wyllie/aws-cli:2.23.7

ARG CDK_VER=2.1100.3

# Install core tooling: Node.js, npm, and AWS CLI v2
RUN apk add --no-cache \
      nodejs \
      npm  \
      && npm install -g aws-cdk@{CDK_VER}

WORKDIR /work

CMD ["/bin/bash"]
