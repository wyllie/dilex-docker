# Architecture

This document describes the architectural principles and image layering strategy used in the **dilex-docker** repository.

The intent is to make the system:

- Predictable
- Reproducible
- Easy to reason about
- Easy to extend without unintended side effects

---

## High-level goals

1. **Single source of truth** for build and deployment toolchains
2. **Clear image layering**, so dependencies are explicit
3. **Pinned versions** everywhere that matters
4. **CI and local parity** (the same images power both)
5. **Minimal base images**, extended only where necessary

---

## Image layering model

The images in this repository form a deliberate dependency tree:

```
ci-base
├── hugo
│   └── hugo-aws
└── cdk

latex (standalone, manual build)
```

Each image has a *single responsibility* and only adds what it strictly needs.

---

## Base image: `ci-base`

`ci-base` is the foundation for all other images.

### What belongs here

Only tools that are:

- universally useful
- extremely stable
- unlikely to cause dependency conflicts

Currently included:

- Alpine Linux (pinned version)
- `bash`
- `ca-certificates`
- `git`
- `tar` (full tar, not BusyBox)

### What does *not* belong here

- Language runtimes (Node, Python, Go)
- Cloud SDKs
- Application binaries
- Compatibility shims unless broadly required

The guiding rule is: **if it’s not needed by *most* images, it doesn’t go here**.

---

## Hugo image: `hugo`

The `hugo` image is designed specifically for building static sites and documentation.

### Key design decisions

#### Upstream binaries

Hugo is installed from **official upstream release binaries**, not Alpine packages.

Reasons:
- Faster access to new Hugo releases
- Exact version pinning
- Avoidance of Alpine packaging delays or revisions (`-r1`, `-r2`, etc.)

#### Alpine compatibility

Because upstream Hugo binaries are built against glibc, the image includes:

- `gcompat`
- `libstdc++`
- `libgcc`

This allows glibc-linked binaries to run correctly on Alpine (musl).

#### Dart Sass

Dart Sass is installed as the **standalone CLI distribution**, not via `npm`:

- No Node.js dependency
- Predictable behavior
- Matches Hugo’s expectations

The full Dart Sass directory is preserved and symlinked to ensure the bundled runtime works correctly.

---

## Hugo + AWS image: `hugo-aws`

`hugo-aws` extends `hugo` with AWS deployment tooling.

### Why this is a separate image

Many Hugo workflows do *not* require AWS access. Keeping AWS tooling separate:

- Reduces attack surface
- Keeps documentation builds lightweight
- Avoids leaking AWS credentials into unnecessary environments

### Additions

- AWS CLI v2 (from Alpine packages)

This image is used for:

- `aws s3 sync`
- CloudFront invalidations
- Deployment automation

---

## CDK image: `cdk`

The `cdk` image is used for AWS infrastructure deployments.

### Included tooling

- Node.js
- npm
- AWS CLI v2

### Inheritance

- Inherits from `ci-base`
- Does *not* inherit from `hugo`

This avoids unnecessary coupling between site-building tools and infrastructure tooling.

---

## LaTeX image: `latex`

The LaTeX image is a standalone build environment.

### Characteristics

- Large image
- Long build time
- Specialized use cases

For these reasons:

- It is **excluded from automatic CI builds**
- It is built **manually via workflow dispatch** when needed

This keeps the primary pipeline fast and reliable.

---

## Build ordering and CI strategy

Image dependencies are respected explicitly in CI:

1. `ci-base`
2. `hugo` and `cdk`
3. `hugo-aws` (depends on `hugo`)

This prevents race conditions where a derived image is built before its base image is published.

LaTeX is intentionally excluded from this flow.

---

## Local vs CI builds

Local builds are optimized for speed and iteration:

- Single-arch by default
- Tagged as `:local`
- Never pushed

CI builds:

- Multi-arch (`amd64`, `arm64`)
- Published to Docker Hub
- Fully reproducible from source

Both paths use the **same Dockerfiles**.

---

## Wrapper-based execution model

Instead of installing tools locally, lightweight shell wrappers are installed into `~/bin`.

These wrappers:

- Invoke the appropriate Docker image
- Mount the working directory
- Preserve user UID/GID
- Forward arguments transparently

This ensures:

- Clean local machines
- Consistent behavior across environments
- Easy upgrades by pulling new images

---

## Future extensions

This architecture is intentionally conservative and extensible.

Expected future additions include:

- Shared `skel` repositories that reference these images
- Additional narrowly-scoped images (e.g. `node-build`, `python-build`)
- Versioned base variants if compatibility needs diverge

Any extension should preserve the core principles:

> *Clear responsibility, minimal coupling, explicit dependencies.*