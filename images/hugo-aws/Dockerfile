

# wyllie/hugo-aws
# Hugo build image + AWS CLI for deploying static sites to S3/CloudFront.

FROM wyllie/hugo:hugo0.154.2-sass1.97.1-alpine3.23.2-1

# Install AWS CLI (v2) from Alpine repos.
# If this package is not available in your repo mirror, switch to the pip/venv install method.
RUN apk add --no-cache aws-cli

WORKDIR /work

CMD ["/bin/bash"]