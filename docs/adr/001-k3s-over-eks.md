# ADR 001: k3s instead of EKS

**Date:** 2026-03-10
**Status:** Accepted

## Context

This is a portfolio project. We need a Kubernetes platform that is cost-effective
and demonstrates infrastructure skills without requiring a production budget.

## Decision

Use k3s on EC2 instead of Amazon EKS.

## Rationale

| Criteria         | k3s on EC2              | EKS                        |
|------------------|-------------------------|----------------------------|
| Monthly cost     | ~$15–30 (t3.medium)     | ~$75+ (control plane only) |
| Setup complexity | Medium (Terraform + k3s)| Higher (node groups, addons)|
| Portfolio signal | IaC + K8s fundamentals  | Managed service usage      |

For a portfolio project with no real traffic, k3s provides a credible Kubernetes
environment at minimal cost while still demonstrating the full IaC + CI/CD stack.

## Consequences

- The k3s control plane must be managed manually (upgrades, patches)
- No native AWS integrations (ALB Ingress Controller, EBS CSI Driver)
  → nginx ingress + local-path provisioner are used instead
