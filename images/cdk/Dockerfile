# grab the latest official version of alpine
FROM alpine:latest

# Install Node.js, npm and bash
RUN apk update && \
    apk add --no-cache bash nodejs npm python3 py3-pip git curl

RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip

RUN /opt/venv/bin/pip install awscli --upgrade

RUN npm install -g aws-cdk

ENV PATH="/opt/venv/bin:$PATH"

# Use a bash entrypoint
CMD ["/bin/bash"]
