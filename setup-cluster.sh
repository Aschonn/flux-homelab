#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------
# Load .env safely
# -----------------------------
if [[ ! -f .env ]]; then
  echo "❌ .env file not found"
  exit 1
fi

set -a
source .env
set +a

# -----------------------------
# Validate required vars
# -----------------------------
REQUIRED_VARS=(
  GIT_EMAIL
  GIT_NAME
  GITHUB_USERNAME
  GITHUB_PAT
  TARGET_REPO
  SETUP_CLUSTERTOKEN
  CLOUDFLARE_API_TOKEN
)

for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "❌ Missing required env var: $var"
    exit 1
  fi
done

echo "✅ Environment loaded for repo: ${GITHUB_USERNAME}/${TARGET_REPO}"

# -----------------------------
# 1) GitHub Repo Bootstrap
# -----------------------------
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_NAME"

git clone https://github.com/Aschonn/flux-homelab
cd flux-homelab

rm -rf .git
git init
git add .
git commit -m "Initializing homelab setup"
git branch -M main
git remote add origin \
  https://${GITHUB_USERNAME}:${GITHUB_PAT}@github.com/${GITHUB_USERNAME}/${TARGET_REPO}.git
git push -u origin main

# -----------------------------
# 2) Install K3s
# -----------------------------
sudo apt update && sudo apt install -y \
  zfsutils-linux \
  nfs-kernel-server \
  cifs-utils \
  open-iscsi

NODE_IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}')

curl -sfL https://get.k3s.io | \
  INSTALL_K3S_VERSION="v1.33.3+k3s1" \
  INSTALL_K3S_EXEC="--node-ip $NODE_IP \
  --disable=flannel,local-storage,metrics-server,servicelb,traefik \
  --flannel-backend=none \
  --disable-network-policy \
  --disable-cloud-controller \
  --disable-kube-proxy" \
  K3S_TOKEN="$SETUP_CLUSTERTOKEN" \
  K3S_KUBECONFIG_MODE=644 sh -s -

mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$(id -u):$(id -g)" ~/.kube/config
chmod 600 ~/.kube/config

kubectl get nodes

# -----------------------------
# 3) Install Helm
# -----------------------------
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# -----------------------------
# 4) Install Cilium
# -----------------------------
helm repo add cilium https://helm.cilium.io
helm repo update

helm install cilium cilium/cilium \
  -n kube-system \
  -f infrastructure/networking/cilium/values.yaml \
  --version 1.18.0 \
  --set operator.replicas=1

# -----------------------------
# 5) Cloudflare Secret (GitOps)
# -----------------------------
kubectl create ns cert-manager
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token="$CLOUDFLARE_API_TOKEN" \
  --namespace cert-manager

# -----------------------------
# 6) Flux Bootstrap (non-redundant)
# -----------------------------
curl -s https://fluxcd.io/install.sh | sudo bash

# Flux ONLY reads GITHUB_TOKEN
export GITHUB_TOKEN="$GITHUB_PAT"

flux bootstrap github \
  --token-auth \
  --owner="$GITHUB_USERNAME" \
  --repository="$TARGET_REPO" \
  --branch=main \
  --path=clusters/my-cluster \
  --personal
  
echo "🚀 Cluster bootstrap complete"
