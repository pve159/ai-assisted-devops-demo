#!/bin/bash
set -euo pipefail

# Install k3s agent
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${k3s_version}" sh -s - agent \
  --server "${k3s_url}" \
  --token "${k3s_token}" \
  --node-label "environment=${environment}" \
  --node-label "role=worker"

echo "k3s agent bootstrap complete."
