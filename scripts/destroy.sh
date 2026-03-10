#!/bin/bash
# Destroy infrastructure for a given environment.
# Usage: ./scripts/destroy.sh <environment>

set -euo pipefail

ENV="${1:?Usage: $0 <environment> (dev|prod)}"

if [[ "${ENV}" == "prod" ]]; then
  echo "WARNING: You are about to destroy PRODUCTION infrastructure."
  read -r -p "Type 'yes-destroy-prod' to confirm: " confirm
  [[ "${confirm}" == "yes-destroy-prod" ]] || { echo "Aborted."; exit 1; }
fi

echo "==> Destroying ${ENV} environment..."
cd "terraform/environments/${ENV}"
terraform init
terraform destroy -auto-approve
echo "==> Done."
