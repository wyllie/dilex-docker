# AWS CDK docker conatiner setup

These commands are used to build a multi-platform docker image and run the dockerfile

```
$ docker login
$ docker buildx create --use
$ docker buildx build --platform linux/arm64,linux/amd64 -t wyllie/aws-cdk-alpine --push .
$ docker run -ir asw-cdk-alpine
```

