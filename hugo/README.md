# hugo docker conatiner setup

These commands are used to build a multi-platform docker image and run the dockerfile

```
$ docker login
$ docker buildx create --use
$ docker buildx build --platform linux/arm64,linux/amd64 -t wyllie/hugo --push .
```

Then to run the container:
```
$ docker pull wyllie/hugo
$ docker run -it wyllie/hugo
```

