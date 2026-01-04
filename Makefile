BIN_DIR := $(HOME)/bin
WRAPPER_DIR := wrappers

# Image tags (single source of truth)
HUGO_IMAGE := wyllie/hugo:hugo0.154.2-sass1.97.1-alpine3.23.2-1
HUGO_AWS_IMAGE := wyllie/hugo-aws:hugo0.154.2-sass1.97.1-awscli2-alpine3.23.2-1
CDK_IMAGE := wyllie/cdk:awscli2-alpine3.23.2-1
CI_BASE_IMAGE := wyllie/ci-base:alpine3.23.2-1
LATEX_IMAGE := wyllie/latex:alpine3.23.2-texlive-1

# Local test tags (for fast iteration without waiting on GitHub Actions)
CI_BASE_LOCAL := wyllie/ci-base:local
HUGO_LOCAL := wyllie/hugo:local
HUGO_AWS_LOCAL := wyllie/hugo-aws:local
CDK_LOCAL := wyllie/cdk:local
LATEX_LOCAL := wyllie/latex:local

# Docker build platforms (used only by buildx targets)
PLATFORMS ?= linux/amd64,linux/arm64

.PHONY: install uninstall check-bin \
	build-ci-base build-hugo build-hugo-aws build-cdk build-latex \
	build-all buildx-ci-base buildx-hugo buildx-hugo-aws buildx-cdk buildx-latex \
	smoke-hugo smoke-hugo-aws smoke-cdk \
	pull-published pull-ci-base pull-hugo pull-hugo-aws pull-cdk pull-latex images-info

check-bin:
	@mkdir -p $(BIN_DIR)

install: check-bin
	@echo "Installing docker-backed CLI wrappers into $(BIN_DIR)"
	@sed "s|@@HUGO_IMAGE@@|$(HUGO_IMAGE)|g" $(WRAPPER_DIR)/hugo > $(BIN_DIR)/hugo
	@sed "s|@@HUGO_AWS_IMAGE@@|$(HUGO_AWS_IMAGE)|g" $(WRAPPER_DIR)/aws > $(BIN_DIR)/aws
	@sed "s|@@CDK_IMAGE@@|$(CDK_IMAGE)|g" $(WRAPPER_DIR)/cdk > $(BIN_DIR)/cdk
	@chmod +x $(BIN_DIR)/hugo $(BIN_DIR)/aws $(BIN_DIR)/cdk
	@echo "✔ Installed: hugo, aws, cdk"

uninstall:
	@echo "Removing docker-backed CLI wrappers from $(BIN_DIR)"
	@rm -f $(BIN_DIR)/hugo $(BIN_DIR)/aws $(BIN_DIR)/cdk
	@echo "✔ Removed"


# -----------------------------
# Local build targets (single-arch, fast)
# -----------------------------

build-ci-base:
	docker build -t $(CI_BASE_LOCAL) images/ci-base

build-hugo: build-ci-base
	docker build -t $(HUGO_LOCAL) images/hugo

build-hugo-aws: build-hugo
	docker build -t $(HUGO_AWS_LOCAL) images/hugo-aws

build-cdk: build-ci-base
	docker build -t $(CDK_LOCAL) images/cdk

build-latex: build-ci-base
	docker build -t $(LATEX_LOCAL) images/latex

build-all: build-ci-base build-hugo build-hugo-aws build-cdk


# -----------------------------
# Local buildx targets (multi-arch, closer to CI)
# Notes:
# - `--load` can only load one arch into the local docker engine; buildx will still validate both.
# - Use `--push` to publish multi-arch manifests.
# -----------------------------

buildx-ci-base:
	docker buildx build --platform $(PLATFORMS) -t $(CI_BASE_LOCAL) --load images/ci-base

buildx-hugo: buildx-ci-base
	docker buildx build --platform $(PLATFORMS) -t $(HUGO_LOCAL) --load images/hugo

buildx-hugo-aws: buildx-hugo
	docker buildx build --platform $(PLATFORMS) -t $(HUGO_AWS_LOCAL) --load images/hugo-aws

buildx-cdk: buildx-ci-base
	docker buildx build --platform $(PLATFORMS) -t $(CDK_LOCAL) --load images/cdk

buildx-latex: buildx-ci-base
	docker buildx build --platform $(PLATFORMS) -t $(LATEX_LOCAL) --load images/latex


# -----------------------------
# Smoke tests (run local tags)
# -----------------------------

smoke-hugo: build-hugo
	docker run --rm $(HUGO_LOCAL) hugo version
	docker run --rm $(HUGO_LOCAL) sass --version

smoke-hugo-aws: build-hugo-aws
	docker run --rm $(HUGO_AWS_LOCAL) hugo version
	docker run --rm $(HUGO_AWS_LOCAL) aws --version

smoke-cdk: build-cdk
	docker run --rm $(CDK_LOCAL) cdk version
	docker run --rm $(CDK_LOCAL) aws --version


# -----------------------------
# Pull published images (pinned tags used by wrappers)
# -----------------------------

images-info:
	@echo "Published images (wrappers use these):"
	@echo "  ci-base   : $(CI_BASE_IMAGE)"
	@echo "  hugo      : $(HUGO_IMAGE)"
	@echo "  hugo-aws  : $(HUGO_AWS_IMAGE)"
	@echo "  cdk       : $(CDK_IMAGE)"

pull-ci-base:
	docker pull $(CI_BASE_IMAGE)

pull-hugo:
	docker pull $(HUGO_IMAGE)

pull-hugo-aws:
	docker pull $(HUGO_AWS_IMAGE)

pull-cdk:
	docker pull $(CDK_IMAGE)

pull-latex:
	docker pull $(LATEX_IMAGE)

pull-published: pull-ci-base pull-hugo pull-hugo-aws pull-cdk
	@echo "✔ Pulled published images"
