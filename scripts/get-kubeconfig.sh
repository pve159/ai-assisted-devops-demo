#!/bin/bash
# Fetch kubeconfig from SSM Parameter Store and configure kubectl.
# Usage: ./scripts/get-kubeconfig.sh <environment>

set -euo pipefail

ENV="${1:?Usage: $0 <environment> (dev|prod)}"
AWS_REGION="${AWS_REGION:-eu-west-3}"
SSM_PATH="/ai-demo/${ENV}/kubeconfig"
OUTPUT="${HOME}/.kube/ai-demo-${ENV}"

mkdir -p "${HOME}/.kube"

echo "==> Fetching kubeconfig from SSM: ${SSM_PATH}"
aws ssm get-parameter \
  --name "${SSM_PATH}" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text \
  --region "${AWS_REGION}" > "${OUTPUT}"

chmod 600 "${OUTPUT}"
echo "==> Kubeconfig saved to ${OUTPUT}"
echo "==> Run: export KUBECONFIG=${OUTPUT}"
