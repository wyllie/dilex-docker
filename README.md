# dilex-containers

![GHCR](https://img.shields.io/github/v/release/DilexNetworks/dilex-containers?label=GHCR&logo=github)
![GHCR Hugo](https://img.shields.io/badge/ghcr-hugo-blue?logo=github)
![Docker Hub](https://img.shields.io/docker/v/wyllie/hugo?label=docker%20hub&logo=docker)


This repository contains the **authoritative container images and tooling** used across Dilex projects for:

- Hugo site builds (docs + websites)
- Deploying static sites to AWS (S3 / CloudFront)
- AWS CDK infrastructure deployments
- (Optionally) LaTeX document builds

The goal of this repo is to provide a **single source of truth** for build and deploy toolchains so that:

- CI and local development use the *same* binaries
- Tool versions are explicit, pinned, and reproducible
- Local machines do not require global installs of Hugo, AWS CLI, CDK, etc.

---

## Images published from this repository

All images are published to **multiple container registries**:

### Docker Hub (primary, personal namespace)

    wyllie/<image>

This remains the default and stable namespace, using a personal Docker Hub account (free tier).

### GitHub Container Registry (GHCR)

    ghcr.io/dilexnetworks/<image>

GHCR images are published directly from GitHub Actions using the native `GITHUB_TOKEN`,
and provide an organization-owned namespace tightly integrated with GitHub.

NOTE: Image tags are kept identical across registries. Additional registries (e.g. AWS ECR)
may be added in the future without breaking existing tags.

### Which registry should I use?

- **Docker Hub (`wyllie/*`)** — recommended for general use, local development, and maximum compatibility.
- **GHCR (`ghcr.io/dilexnetworks/*`)** — recommended for GitHub-native workflows, CI usage, and organization-owned pulls.

Both registries publish identical images and tags.

### Example pulls

Docker Hub:

```bash
docker pull wyllie/hugo:main
```

GHCR:

```bash
docker pull ghcr.io/dilexnetworks/hugo:main
```

---

### `wyllie/ci-base`
Minimal base image shared by all other images.

Includes:
- Alpine Linux (pinned)
- `bash`
- `ca-certificates`
- `git`
- `tar` (full tar, not BusyBox)

This image centralizes the Alpine version so upgrading Alpine happens **in one place**.

---

### `wyllie/hugo`
Hugo build image for documentation sites and static websites.

Includes:
- Hugo **Extended** (installed from upstream release binaries)
- Dart Sass (standalone CLI, no Node dependency)
- `gcompat`, `libstdc++`, `libgcc` to support upstream binaries on Alpine

Notes:
- Hugo is installed from upstream releases (not Alpine packages)
- Multi-arch safe (`linux/amd64`, `linux/arm64`)

---

### `wyllie/hugo-aws`
Extends `wyllie/hugo` with AWS deployment tooling.

Includes:
- Everything from `wyllie/hugo`
- AWS CLI v2 (from Alpine packages)

Used for:
- `aws s3 sync`
- CloudFront invalidations

---

### `wyllie/cdk`
AWS CDK deployment image.

Includes:
- Node.js + npm
- AWS CLI v2
- Inherits base tooling from `wyllie/ci-base`

Used for:
- `cdk synth`
- `cdk deploy`

---

### `wyllie/latex` (manual build only)
LaTeX build image (currently built manually on demand).

Includes:
- TeX Live
- Custom Beamer theme

This image is **not** built automatically due to long build times. It can be built manually via GitHub Actions.

---

## GitHub Actions

This repository includes a GitHub Actions workflow that:

- Builds all primary images (`ci-base`, `hugo`, `cdk`, then `hugo-aws`)
- Publishes multi-arch images (`amd64`, `arm64`) to Docker Hub
- Uses strict build ordering to respect image dependencies

### Triggers

- **Push to `main`** → build & push images
- **Pull requests** → build only (no push)
- **Manual dispatch** → optional LaTeX build

LaTeX is excluded from the default pipeline and can be built manually using a workflow input.

---

## Local development (no waiting on CI)

A `Makefile` is provided for fast local testing of Docker images.

### Local builds (single-arch, fast)

```bash
make build-ci-base
make build-hugo
make build-hugo-aws
make build-cdk
make build-all
```

Images are tagged locally as `:local` and never pushed.

### Local multi-arch builds (closer to CI)

```bash
make buildx-hugo
make buildx-hugo-aws
```

---

## Smoke tests

Quick sanity checks for locally built images:

```bash
make smoke-hugo
make smoke-hugo-aws
make smoke-cdk
```

---

## Docker-backed CLI wrappers

This repo can install lightweight wrappers into `~/bin` so you can **use Docker instead of local installs**.

After installation:

```bash
hugo version
aws --version
cdk version
```

All commands run inside Docker using pinned images.

### Install wrappers

```bash
make install
```

### Remove wrappers

```bash
make uninstall
```

---

## Pulling published images

To sync your local machine with the published toolchain:

```bash
make images-info
make pull-published
```

Individual pulls are also available:

```bash
make pull-hugo
make pull-hugo-aws
make pull-cdk
```

---

## Releases

Releases are cut manually using:

    make release RELEASE=patch|minor|major

Publishing a release automatically builds and publishes container images.

## Design principles

- **Single source of truth** for build toolchains
- **Pinned versions** for reproducibility
- **Docker-first** (local machines stay clean)
- **CI and local parity**
- **Boring and reliable by design**

This repository is intended to be used alongside future `skel` (skeleton) repositories so new projects can start with a known-good toolchain immediately.