# ADR 002: GHCR instead of ECR

**Date:** 2026-03-10
**Status:** Accepted

## Context

We need a container registry to store the demo-app Docker image.

## Decision

Use GitHub Container Registry (GHCR) instead of Amazon ECR.

## Rationale

| Criteria       | GHCR                          | ECR                            |
|----------------|-------------------------------|--------------------------------|
| Cost           | Free for public repositories  | ~$0.10/GB storage + transfer   |
| Authentication | GITHUB_TOKEN (built-in)       | Requires AWS credentials       |
| Bootstrap      | None                          | Terraform resource required    |
| Integration    | Native to GitHub Actions      | Extra step (aws ecr get-login) |

Since the repository is public and all CI/CD runs on GitHub Actions, GHCR
requires zero additional setup and keeps the AWS footprint minimal.

## Consequences

- Images are public (acceptable for a demo project)
- No ECR lifecycle policies — old images must be cleaned up via GHCR settings
