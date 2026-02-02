#!/bin/bash
# setup-homelab.sh
# Full homelab setup: GitHub repo, K3s, Helm, Cilium, Cloudflare secret, FluxCD

set -euo pipefail
IFS=$'\n\t'

# -----------------------------
# 1) Create a blank GitHub repo
# -----------------------------
echo "=== Step 1: Creating GitHub repo ==="

read -p "GitHub Email: " GIT_EMAIL
read -p "GitHub Name: " GIT_NAME
read -p "GitHub Username: " GITHUB_USERNAME
read -s -p "GitHub Personal Access Token: " GITHUB_PAT
echo
read -p "Target Repo Name: " TARGET_REPO

git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_NAME"

echo "Cloning template repo..."
git clone https://github.com/Aschonn/flux-homelab && cd flux-homelab
rm -rf .git
git init
git add .
git commit -m "Initializing homelab setup"
git branch -M main
git remote add origin https://${GITHUB_USERNAME}:${GITHUB_PAT}@github.com/${GITHUB_USERNAME}/${TARGET_REPO}.git
git push -u origin main

cd ..

# -----------------------------
# 2) Install K3s
# -----------------------------
echo "=== Step 2: Installing K3s ==="

sudo apt update && sudo apt install -y \
  zfsutils-linux \
  nfs-kernel-server \
  cifs-utils \
  open-iscsi

export SETUP_NODEIP=$(ip route get 1.1.1.1 | awk '{print $7; exit}')
read -s -p "Set your K3s cluster token (super secret): " SETUP_CLUSTERTOKEN
echo

curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.33.3+k3s1" \
  INSTALL_K3S_EXEC="--node-ip $SETUP_NODEIP \
  --disable=flannel,local-storage,metrics-server,servicelb,traefik \
  --flannel-backend='none' \
  --disable-network-policy \
  --disable-cloud-controller \
  --disable-kube-proxy" \
  K3S_TOKEN=$SETUP_CLUSTERTOKEN \
  K3S_KUBECONFIG_MODE=644 sh -s -

mkdir -p $HOME/.kube
sudo cp -i /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
chmod 600 $HOME/.kube/config

echo "Testing K3s connectivity..."
kubectl get po -A

# -----------------------------
# 3) Install Helm
# -----------------------------
echo "=== Step 3: Installing Helm ==="
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# -----------------------------
# 4) Install Cilium
# -----------------------------
echo "=== Step 4: Installing Cilium ==="
helm repo add cilium https://helm.cilium.io
helm repo update
helm install cilium cilium/cilium -n kube-system \
  -f infrastructure/networking/cilium/values.yaml \
  --version 1.18.0 \
  --set operator.replicas=1

# -----------------------------
# 5) Create Secret for Cloudflare
# -----------------------------
echo "=== Step 5: Creating Cloudflare secret ==="
read -s -p "Enter Cloudflare API Token: " CLOUDFLARE_TOKEN
echo
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token=$CLOUDFLARE_TOKEN \
  --namespace cert-manager \
  --dry-run=client -o yaml > infrastructure/networking/cert-manager/config/cloudflare-api-token.yaml

# -----------------------------
# 6) Install and Configure Flux
# -----------------------------
echo "=== Step 6: Installing FluxCD ==="
curl -s https://fluxcd.io/install.sh | sudo bash

read -p "Flux GitHub Repo Name (for bootstrap): " FLUX_REPO
flux bootstrap github \
  --token-auth \
  --owner=$GITHUB_USERNAME \
  --repository=$FLUX_REPO \
  --branch=main \
  --path=clusters/my-cluster \
  --personal

echo "=== Homelab Setup Complete! ==="
