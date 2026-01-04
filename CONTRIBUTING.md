

# Contributing

Thanks for your interest in contributing to **dilex-docker**.

This repository provides the **foundational build toolchains** used across Dilex projects, so changes here should be made deliberately and with care.

---

## Guiding principles

All contributions should preserve the following principles:

1. **Single responsibility** – each image does one thing well
2. **Explicit dependencies** – no hidden coupling between images
3. **Pinned versions** – avoid floating or implicit versions
4. **Reproducibility** – CI and local builds must behave the same
5. **Boring by design** – reliability beats cleverness

If a change violates one of these principles, it probably does not belong here.

---

## Repository structure

```
images/
  ci-base/
  hugo/
  hugo-aws/
  cdk/
  latex/
wrappers/
Makefile
.github/workflows/
```

- Each directory under `images/` produces exactly one Docker image
- Images may only inherit from explicitly documented base images
- `wrappers/` contains local CLI wrappers (no business logic)

---

## Making changes

### Small changes

Examples:
- Bumping a tool version
- Fixing a Dockerfile issue
- Improving documentation

Steps:
1. Make the change
2. Build locally using the Makefile
3. Run the relevant smoke test
4. Commit with a clear message

---

### Significant changes

Examples:
- Adding a new image
- Changing image inheritance
- Introducing a new runtime or compatibility layer

Before implementing:

- Ensure the change fits the architectural model
- Update `ARCHITECTURE.md` if layering changes
- Update `VERSIONING.md` if tagging semantics change

Prefer explicit discussion in the commit message explaining *why* the change exists.

---

## Local development workflow

Local iteration is encouraged and preferred before pushing changes.

Typical flow:

```bash
make build-hugo
make smoke-hugo
```

For derived images:

```bash
make build-hugo-aws
make smoke-hugo-aws
```

Local images are tagged as `:local` and are never pushed.

---

## CI behavior

GitHub Actions will:

- Build images on pull requests (no push)
- Build and publish images on merges to `main`
- Enforce image build ordering

Long-running or experimental images (e.g. LaTeX) should **not** be added to the default pipeline.

---

## Versioning rules

- Never use `:latest`
- Never reference floating tags in `FROM` statements
- Always bump the image revision (`-N`) when changing Dockerfile logic

Refer to `VERSIONING.md` for full details.

---

## Adding a new image

Before adding a new image, consider:

- Can this be expressed as a small extension of an existing image?
- Does it require a new runtime or large dependency set?
- Will it significantly slow down CI builds?

If a new image is justified:

1. Create a new directory under `images/`
2. Document its purpose in `README.md`
3. Add it to `ARCHITECTURE.md`
4. Add local build targets to the Makefile
5. Decide whether it belongs in automatic CI or manual builds

---

## Documentation expectations

Documentation is considered part of the codebase.

Any change that affects:

- image contents
- build behavior
- versioning
- inheritance

must be reflected in the relevant documentation files.

---

## Style and conventions

- Keep Dockerfiles readable and explicit
- Prefer clarity over brevity
- Avoid unnecessary abstraction or indirection
- Comment *why* something exists, not *what* it does

---

## Final note

This repository is intentionally conservative.

It is easier to add tooling later than to remove complexity once it has spread across projects. When in doubt, keep changes minimal and explicit.