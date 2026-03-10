# Getting Started

## Prerequisites

- AWS account with administrator-level access (required for the bootstrap step only)
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.10.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) with the [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) (for SSM access)

> **No SSH key required.** All admin access to instances goes through AWS SSM Session Manager.

## 1. Deploy the bootstrap stack

The bootstrap stack provisions the S3 state bucket and the IAM role used by
GitHub Actions. It uses a **local** backend and must be run **once** with
admin-level credentials.

```bash
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars:
#   - Set create_oidc_provider = false if a GitHub OIDC provider already exists
#     in your account, and provide existing_oidc_provider_arn.
terraform init
terraform apply
```

The outputs include the IAM role ARN needed in the next step. Keep the
`terraform.tfstate` file safe (e.g. in a password manager).

## 2. Configure GitHub repository secrets and variables

In your repository go to **Settings → Secrets and variables → Actions**:

| Type   | Name                 | Value                                        |
|--------|----------------------|----------------------------------------------|
| Secret | `AWS_OIDC_ROLE_ARN`  | `github_actions_role_arn` output from step 1 |
| Secret | `INFRACOST_API_KEY`  | Free key from https://www.infracost.io       |

## 3. Deploy an environment

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars has sensible defaults — no edits required for dev
terraform init
terraform apply
```

The outputs show the SSM commands to connect to the cluster.

## 4. Configure kubectl via SSM port forwarding

The kubeconfig is stored in SSM Parameter Store. Retrieve it and open a tunnel
to reach the k3s API through the bastion's HAProxy:

```bash
# Terminal 1 — open the SSM port-forwarding tunnel (keep it open)
aws ssm start-session \
  --target <bastion_instance_id> \
  --region eu-west-3 \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"localPortNumber":["6443"],"portNumber":["6443"]}'

# Terminal 2 — fetch and patch the kubeconfig
aws ssm get-parameter \
  --name "/ai-demo/dev/kubeconfig" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text \
  | sed 's|server: https://[^:]*:|server: https://127.0.0.1:|' \
  > ~/.kube/ai-demo-dev

export KUBECONFIG=~/.kube/ai-demo-dev
kubectl get nodes
```

The exact commands with real instance IDs are printed by `terraform output`.

## 5. Connect to a node (optional)

```bash
# Bastion
aws ssm start-session --target <bastion_instance_id> --region eu-west-3

# k3s master
aws ssm start-session --target <master_instance_id> --region eu-west-3
```

## 6. Deploy the application

```bash
kubectl apply -k kubernetes/overlays/dev
kubectl get pods -n demo
```

## Tear down

```bash
./scripts/destroy.sh dev
```
