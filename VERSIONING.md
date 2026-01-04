

# Versioning

This document describes how Docker image versions and tags are managed in the **dilex-docker** repository.

The goal of the versioning scheme is to be:

- Explicit and readable
- Deterministic and reproducible
- Easy to reason about when debugging or rolling back
- Stable over time

---

## Core principles

1. **Versions are encoded in tags**, not inferred
2. **Images are immutable once published**
3. **Tags describe what is inside the image**, not when it was built
4. **Human readability matters more than brevity**

---

## Tag structure

All published images follow a descriptive tag format rather than a single opaque version number.

Example:

```
wyllie/hugo:hugo0.154.2-sass1.97.1-alpine3.23.2-1
```

This tag can be read left-to-right as:

- `hugo0.154.2` – Hugo upstream version
- `sass1.97.1` – Dart Sass version
- `alpine3.23.2` – Alpine Linux base version
- `-1` – image revision number

---

## Component versions

### Application versions

For application-level tools (Hugo, Dart Sass, AWS CLI, CDK):

- Versions correspond to **upstream project versions**
- Alpine package revision suffixes (e.g. `-r1`) are *not* used unless the tool is installed via `apk`

Examples:

- `hugo0.154.2`
- `sass1.97.1`
- `awscli2`

---

### Base OS version

All images encode the Alpine Linux version explicitly:

```
alpine3.23.2
```

This ensures:

- ABI expectations are clear
- Security updates are intentional
- Alpine upgrades are visible and auditable

Alpine version changes are centralized in the `ci-base` image.

---

## Image revision (`-N` suffix)

The final numeric suffix (e.g. `-1`) is the **image revision**.

This number is incremented when:

- The Dockerfile changes
- Build tooling changes
- Dependencies change *without* a version bump (e.g. layout fixes, compatibility fixes)

This allows corrections without changing the semantic meaning of the tag.

Example:

```
- alpine3.23.2-1
- alpine3.23.2-2
```

---

## `:main` tag

In addition to pinned tags, each image is also published with a `:main` tag.

Example:

```
wyllie/hugo:main
```

### Semantics

- `:main` always points to the **latest successful build on the `main` branch**
- It is a *moving tag*
- It should be treated as **convenience**, not a stability guarantee

### Intended use

- Local experimentation
- CI environments where exact pinning is not required
- Development workflows

Pinned tags should always be preferred for production or long-lived environments.

---

## Local tags

Local builds use the `:local` tag:

```
wyllie/hugo:local
```

Characteristics:

- Never pushed to Docker Hub
- Architecture-specific
- Safe for rapid iteration

Local tags exist solely to speed up development and testing.

---

## Multi-architecture support

All published images are built for:

- `linux/amd64`
- `linux/arm64`

Docker Hub manifests ensure the correct architecture is pulled automatically.

Architecture differences **do not** affect tag names.

---

## Dependency alignment

Derived images must always reference **fully qualified pinned tags** of their base images.

Example:

```dockerfile
FROM wyllie/hugo:hugo0.154.2-sass1.97.1-alpine3.23.2-1
```

Never use:

- `:latest`
- floating tags in `FROM` statements

This prevents accidental breakage from upstream changes.

---

## When to bump what

| Change | Action |
|------|--------|
| Hugo upgrade | Update `hugoX.Y.Z` in tag |
| Dart Sass upgrade | Update `sassX.Y.Z` in tag |
| Alpine upgrade | Update `alpineX.Y.Z` everywhere |
| Dockerfile logic fix | Increment image revision (`-N`) |
| CI-only changes | No tag change unless output differs |

---

## Relationship to Git tags

Docker image tags are **not required** to mirror Git tags.

Git tags may be used to mark repository milestones, but:

- Docker tags describe *contents*
- Git tags describe *source state*

They are intentionally decoupled.

---

## Design intent

This versioning system favors:

- Clarity over cleverness
- Explicitness over automation
- Stability over convenience

The result is a toolchain that can be understood months or years later without guesswork.