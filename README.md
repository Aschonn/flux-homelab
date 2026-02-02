<img width="1913" height="994" alt="image" src="https://github.com/user-attachments/assets/830f84f4-317d-4cf7-8ca2-7d42f5554801" />



# Flux Homelab

For this setup I used terraform from my homelab to setup up the node. I will be creating a barebones k3s cluster with all the basic necessarities (infrastructure, monitoring, storage, etc..) to have a functioning gitops repo and cluster. This includes https certificates generated via dns from cloudflare. By the end of this tutorial you should have a functioning cluster with visability to boot local via your network.

Ps. I used local DNS in order for this to work. I used Technitium DNS which is an open source dhcp server that can be installed using if interested:

Flux Concepts:

https://fluxcd.io/flux/concepts/

---

## Requirements:
1) a server
2) github repo
3) personal access token gh and cloudflare api token
   
## ⚙️ Tutorial

### Remote into the server and install these dependencies

### 1) Create a blank Github Repo

```bash
export GIT_EMAIL="github_email"
export GIT_NAME="github_name"
export GITHUB_USERNAME="github_username"
export GITHUB_PAT="personal_access_token"  
export TARGET_REPO="your_repo_name"               

git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_NAME"
git clone https://github.com/Aschonn/flux-homelab && cd flux-homelab
rm -rf .git
git init
git add .
git status
git commit -m "Initializing homelab setup"
git branch -M main
git remote add origin https://${GITHUB_USERNAME}:${GITHUB_PAT}@github.com/${GITHUB_USERNAME}/${TARGET_REPO}.git
git push -u origin main

```
---


### 2) Install K3S

Before installing K3s, set your node IP and cluster token:

```bash
sudo apt update && sudo apt install -y \
  zfsutils-linux \
  nfs-kernel-server \
  cifs-utils \
  open-iscsi  # Optional
export SETUP_NODEIP=$(ip route get 1.1.1.1 | awk '{print $7; exit}')
export SETUP_CLUSTERTOKEN=superduperrandomsecret  # Strong token
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
```
```bash
# test for connectivity
kubectl get po -A
```


---


### 3) Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

---

### 4) Install Cilium

```bash
helm repo add cilium https://helm.cilium.io && helm repo update
helm install cilium cilium/cilium -n kube-system \
  -f infrastructure/networking/cilium/values.yaml \
  --version 1.18.0 \
  --set operator.replicas=1
```
---
### 5)  Create Secret for Cloudflare

```bash
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token=<APITOKEN> \
  --namespace cert-manager \
  --dry-run=client -o yaml > infrastructure/networking/cert-manager/config/cloudflare-api-token.yaml
```

### 6)  Install and Configure Flux 

#### You'll need to grab an access token from github with these permissions:

https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens

```bash

curl -s https://fluxcd.io/install.sh | sudo bash
flux bootstrap github \
  --token-auth \
  --owner=aschonn \
  --repository=<name of repo> \
  --branch=main \
  --path=clusters/my-cluster \
  --personal


```
---


### Helpful Tools

#### k9s (Kubernetes CLI UI)

```bash
curl -sS https://webinstall.dev/k9s | bash
source ~/.config/envman/PATH.env
```

