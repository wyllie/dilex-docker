FROM wyllie/ci-base:alpine3.23.2-1

ARG AWSCLI_VER=2.32.7-r0

RUN apk add --no-cache aws-cli=${AWSCLI_VER}

CMD ["/bin/bash"]
