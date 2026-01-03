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


## ⚠️  Alpine edge packages (intentional)

This Docker image intentionally enables Alpine edge repositories.

Why?
+ Hugo extended (required for SCSS/Sass pipelines) is provided via edge/community
+ Dart Sass (dart-sass) is currently available via edge/testing
+ Hugo’s SCSS support requires a real sass binary on PATH

This setup allows Hugo to compile SCSS using Dart Sass without relying on Node/npm-based Sass tooling.

Trade-offs
+ Edge packages may change more frequently than stable Alpine releases
+ Versions are pinned at build time via the Docker image, not runtime

If this becomes a problem in the future, alternatives include:
+ Installing Dart Sass via npm
+ Switching to a multi-stage build
+ Using a Debian-based image

For now, edge is the secret weapon that keeps the image simple and Hugo happy.
