#!/bin/bash
set -euo pipefail

# Install k3s server
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${k3s_version}" K3S_TOKEN="${k3s_token}" sh -s - server \
  --write-kubeconfig-mode 644 \
  --disable traefik \
  --disable servicelb \
  --disable local-storage \
  --node-label "environment=${environment}"

# Wait until the node is Ready
until kubectl get nodes 2>/dev/null | grep -q " Ready"; do
  echo "Waiting for k3s to be ready..."
  sleep 5
done

# Use the instance's PRIVATE IP (no public IP in private subnet)
PRIVATE_IP=$(curl -sf http://169.254.169.254/latest/meta-data/local-ipv4)
sed "s/127.0.0.1/$${PRIVATE_IP}/g" /etc/rancher/k3s/k3s.yaml > /tmp/kubeconfig

# Store kubeconfig in SSM Parameter Store
aws ssm put-parameter \
  --name "${ssm_path}" \
  --value "$(cat /tmp/kubeconfig)" \
  --type SecureString \
  --overwrite \
  --region "${aws_region}"

rm -f /tmp/kubeconfig
echo "k3s bootstrap complete."
