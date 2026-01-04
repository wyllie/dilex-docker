BIN_DIR := $(HOME)/bin
WRAPPER_DIR := wrappers

# Versioning / releases
# - Version is stored in version.txt (semver like 0.1.0)
# - `make release RELEASE=patch|minor|major` will bump, commit, tag, push, and create a GitHub release (if `gh` is installed)
VERSION_FILE := version.txt
RELEASE_PREFIX ?= v
DEFAULT_VERSION ?= 0.1.0

# Release controls
# - Set DRY_RUN=1 to preview commands without changing anything
DRY_RUN ?= 0

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
	pull-published pull-ci-base pull-hugo pull-hugo-aws pull-cdk pull-latex images-info \
	version-init version-show version-set bump-version release commit-release tag-release push-release gh-release

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


# -----------------------------
# Versioning / Release (manual)
# -----------------------------

# Ensure we have a version file.
version-init:
	@if [ ! -f "$(VERSION_FILE)" ]; then \
		echo "$(DEFAULT_VERSION)" > "$(VERSION_FILE)"; \
		echo "✔ Created $(VERSION_FILE) with $(DEFAULT_VERSION)"; \
	fi

# Print the current version (e.g., 0.1.0)
version-show: version-init
	@cat "$(VERSION_FILE)"

# Set version explicitly: `make version-set VERSION=0.2.0`
version-set:
	@[ -n "$(VERSION)" ] || { echo "❌ VERSION is required (e.g., make version-set VERSION=0.2.0)"; exit 2; }
	@echo "$(VERSION)" > "$(VERSION_FILE)"
	@echo "✔ Set version to $(VERSION)"

# Bump semver in version.txt. Usage: `make bump-version RELEASE=patch|minor|major`
# - patch: 0.1.0 -> 0.1.1
# - minor: 0.1.0 -> 0.2.0
# - major: 0.1.0 -> 1.0.0
bump-version: version-init
	@[ -n "$(RELEASE)" ] || { echo "❌ RELEASE is required (patch|minor|major)"; exit 2; }
	@# Prefer bump2version if configured; fallback to a tiny semver bump (no heredocs; avoids Make tab/space pitfalls).
	@if command -v bump2version >/dev/null 2>&1 && { [ -f .bumpversion.cfg ] || [ -f setup.cfg ] || [ -f pyproject.toml ]; }; then \
		if [ "$(DRY_RUN)" = "1" ]; then \
			echo "DRY_RUN bump2version --no-commit --no-tag $(RELEASE)"; \
		else \
			bump2version --no-commit --no-tag "$(RELEASE)"; \
		fi; \
	else \
		if [ "$(DRY_RUN)" = "1" ]; then \
			echo "DRY_RUN python3 semver bump $(RELEASE) -> $(VERSION_FILE)"; \
		else \
			python3 -c 'import os,re,sys; part=os.environ.get("RELEASE"); path=os.environ.get("VERSION_FILE","version.txt"); v=open(path,"r",encoding="utf-8").read().strip();\n\
assert re.fullmatch(r"\\d+\\.\\d+\\.\\d+", v), f"Invalid version in {path}: {v}";\n\
major,minor,patch=map(int,v.split("."));\n\
(major,minor,patch) = (major, minor, patch+1) if part=="patch" else (major, minor+1, 0) if part=="minor" else (major+1,0,0) if part=="major" else (_ for _ in ()).throw(SystemExit("RELEASE must be patch|minor|major"));\n\
new=f"{major}.{minor}.{patch}"; open(path,"w",encoding="utf-8").write(new+"\\n"); print(new)'; \
		fi; \
	fi
	@echo "✔ Bumped version to $$(cat \"$(VERSION_FILE)\")"

# Commit the version bump.
commit-release: version-init
	@V=$$(cat "$(VERSION_FILE)" | tr -d ' \t\n\r'); \
	[ -n "$$V" ] || { echo "❌ $(VERSION_FILE) is empty"; exit 2; }; \
	if [ "$(DRY_RUN)" = "1" ]; then \
		echo "DRY_RUN git add $(VERSION_FILE)"; \
		echo "DRY_RUN git commit -m 'chore(release): $(RELEASE_PREFIX)$$V'"; \
	else \
		git add "$(VERSION_FILE)"; \
		git commit -m "chore(release): $(RELEASE_PREFIX)$$V"; \
	fi

# Create a lightweight git tag (e.g., v0.1.1)
tag-release: version-init
	@V=$$(cat "$(VERSION_FILE)" | tr -d ' \t\n\r'); \
	TAG="$(RELEASE_PREFIX)$$V"; \
	if [ "$(DRY_RUN)" = "1" ]; then \
		echo "DRY_RUN git tag $$TAG"; \
	else \
		git tag "$$TAG"; \
	fi
	@echo "✔ Tagged $$TAG"

# Push commits + tags.
push-release:
	@if [ "$(DRY_RUN)" = "1" ]; then \
		echo "DRY_RUN git push"; \
		echo "DRY_RUN git push --tags"; \
	else \
		git push; \
		git push --tags; \
	fi

# Create a GitHub release if `gh` is installed. Safe no-op otherwise.
gh-release: version-init
	@V=$$(cat "$(VERSION_FILE)" | tr -d ' \t\n\r'); \
	TAG="$(RELEASE_PREFIX)$$V"; \
	if command -v gh >/dev/null 2>&1; then \
		if [ "$(DRY_RUN)" = "1" ]; then \
			echo "DRY_RUN gh release create $$TAG --title '$$TAG' --notes 'Release $$TAG'"; \
		else \
			gh release create "$$TAG" --title "$$TAG" --notes "Release $$TAG"; \
		fi; \
	else \
		echo "ℹ️  'gh' not found; skipping GitHub release creation"; \
	fi

# One-shot release target.
# Usage: make release RELEASE=patch|minor|major
release: bump-version commit-release tag-release push-release gh-release
	@echo "✔ Release complete: $(RELEASE_PREFIX)$$(cat "$(VERSION_FILE)")"
