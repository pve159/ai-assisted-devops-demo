# Architecture

## Overview

```
GitHub PR   →  CI (fmt / validate / tflint / plan / infracost)  →  Review
GitHub main →  CD (terraform apply  +  kubectl apply)
```

## Infrastructure diagram

```
┌───────────────────────────────────────────────────────────────────────┐
│  AWS — eu-west-3                                                      │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  VPC: ai-demo-dev-vpc (10.0.0.0/16)                            │  │
│  │                                                                 │  │
│  │  ┌───────────────────────────────────────────────────────────┐  │  │
│  │  │  Public Subnet  10.0.1.0/24  (eu-west-3a)                │  │  │
│  │  │                                                           │  │  │
│  │  │  ┌───────────────────────────────────────────────────┐   │  │  │
│  │  │  │  ai-demo-bastion  (t3.micro, Elastic IP)          │   │  │  │
│  │  │  │  • NAT instance (source_dest_check = false)       │   │  │  │
│  │  │  │  • HAProxy → k3s API :6443 (dynamic discovery)    │   │  │  │
│  │  │  │  • HAProxy → ingress :80/:443                     │   │  │  │
│  │  │  │  • Admin access: AWS SSM Session Manager only     │   │  │  │
│  │  │  └───────────────────────────────────────────────────┘   │  │  │
│  │  └───────────────────────────────────────────────────────────┘  │  │
│  │                                                                 │  │
│  │  ┌───────────────────────────────────────────────────────────┐  │  │
│  │  │  Private Subnet 1  10.0.10.0/24  (eu-west-3a)            │  │  │
│  │  │                                                           │  │  │
│  │  │  ┌─────────────────┐   ┌──────────────┐ ┌─────────────┐ │  │  │
│  │  │  │ k3s-master-1    │   │ k3s-worker   │ │ k3s-worker  │ │  │  │
│  │  │  │ t3.medium       │   │ t3.medium    │ │ t3.medium   │ │  │  │
│  │  │  └─────────────────┘   └──────────────┘ └─────────────┘ │  │  │
│  │  └───────────────────────────────────────────────────────────┘  │  │
│  │                                                                 │  │
│  │  ┌───────────────────────────────────────────────────────────┐  │  │
│  │  │  Private Subnet 2  10.0.11.0/24  (eu-west-3b)            │  │  │
│  │  │                                                           │  │  │
│  │  │  ┌─────────────────┐   ┌──────────────┐ ┌─────────────┐ │  │  │
│  │  │  │ k3s-master-2    │   │ k3s-worker   │ │ k3s-worker  │ │  │  │
│  │  │  │ t3.medium       │   │ t3.medium    │ │ t3.medium   │ │  │  │
│  │  │  └─────────────────┘   └──────────────┘ └─────────────┘ │  │  │
│  │  └───────────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  SSM Parameter Store: /ai-demo/{env}/kubeconfig (SecureString)        │
│  S3: ai-demo-terraform-state-<account_id>  (versioned, encrypted)     │
│  IAM: ai-demo-github-actions-role  (OIDC ← GitHub Actions)            │
└───────────────────────────────────────────────────────────────────────┘
```

## Module dependency graph

```
environments/dev  (or prod)
  └── module "platform"
        ├── module "network"       VPC, subnets (1 public + 2 private), security groups
        ├── module "bastion"       EC2 t3.micro + Elastic IP — NAT + HAProxy
        ├── aws_route_table        Private route tables → bastion ENI (NAT)
        ├── module "k3s-masters"   2× EC2 (one per private subnet) — k3s server
        └── module "k3s-workers"   ASG — k3s agents (workers_per_subnet × 2 subnets)
```

## Deployment flow

```
1. terraform/bootstrap        →  S3 bucket + IAM role (once, with admin credentials)
2. terraform/environments/dev →  VPC + bastion + k3s cluster (via GitHub Actions)
3. kubernetes/overlays/dev    →  demo-app deployment
```

## Network flow

```
Inbound (app traffic):
  Internet → Bastion EIP :80/:443 → HAProxy → k3s ingress controller

Admin (SSM):
  Engineer → AWS SSM API → SSM agent on EC2 → shell session (no port 22 open)

kubectl (SSM port forwarding):
  Engineer → SSM → bastion:6443 → HAProxy → k3s API → local kubectl

Outbound (nodes → internet):
  k3s nodes → private route table → bastion ENI → iptables NAT masquerade → Internet
```

## Security model

- **No long-lived AWS credentials**: GitHub Actions authenticates via **OIDC** (no access keys stored in GitHub)
- **No SSH access**: port 22 is not open anywhere; all admin access goes through **AWS SSM Session Manager**
- **No EC2 key pairs**: instances have no key pairs attached
- **Private nodes**: k3s masters and workers have no public IPs; only the bastion has an Elastic IP
- **SSM core policy**: all EC2 instances have `AmazonSSMManagedInstanceCore` managed policy
- **Kubeconfig stored in SSM Parameter Store** (SecureString, KMS-encrypted)
- **All EBS volumes encrypted at rest**
- **IAM roles scoped to least privilege**: k3s nodes can only read/write `/ai-demo/*` SSM parameters; bastion can only call `ec2:DescribeInstances`
- **GitHub Actions role scoped to this repository** via OIDC `sub` claim condition
