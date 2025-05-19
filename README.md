# Monorepo POC for Containers

This repository is a proof of concept (POC) for using a monorepo structure with containerized services/packages.

## Structure
- `core.registry/` — Core registry logic and supporting code for the POC.
  - `pipelines/` — CI/CD and automation scripts
  - `infra/` — Infrastructure as code (IaC) and deployment configs
  - `modules/` — Modular application/business logic
  - `tests/` — Unit and integration tests
- (Optional) `packages/` — Place for individual services or libraries if you add them later.

## Getting Started
1. Add your first module, infra, or pipeline in the `core.registry/` directory.
2. Add a `Dockerfile` to any service or module you want to containerize.
3. Use `docker-compose.yml` at the root for multi-service orchestration (optional).

## Example
```
core.registry/
  modules/
  infra/
  pipelines/
  tests/
```

## Next Steps
- Add your code to the appropriate subfolder in `core.registry/`.
- Build and run containers using Docker.

---
This is a minimal starting point. Expand as needed for your POC.
