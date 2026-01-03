# Use a pinned Alpine (recommended vs :latest)
FROM alpine:3.20

# Add edge repos for hugo (community) and dart-sass (testing)
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

# Install tooling (hugo from edge/community; dart-sass from edge/testing)
RUN apk add --no-cache \
      bash ca-certificates curl dart-sass git python3 py3-pip go \
      hugo tar wget

# Install the AWS CLI in its own venv
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir --upgrade awscli

# Add a few directories to the path
ENV PATH="/usr/local/go/bin:/opt/venv/bin:/usr/local/bin:$PATH"

WORKDIR /app
CMD ["/bin/bash"]
