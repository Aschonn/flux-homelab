<img width="1907" height="835" alt="image" src="https://github.com/user-attachments/assets/83bb9d35-0f03-40ee-a888-879d9d09ab82" />


# flux-homelab

For this setup I used terraform from my homelab to setup up the node. I will be creating a barebones k3s cluster with all the basic necessarities (infrastructure, monitoring, storage, etc..) to have a functioning gitops repo and cluster. This includes https certificates generated via dns from cloudflare. By the end of this tutorial you should have a functioning cluster with visability to boot local via your network.

Ps. I used local DNS in order for this to work. I used Technitium DNS which is an open source dhcp server that can be installed using if interested:

### https://community-scripts.github.io/ProxmoxVE/scripts?id=technitiumdns


**Specs:** Ubuntu 24.04

---

## Requirements:
1) a server
2) github repo (optional)

## ⚙️ Tutorial

### Remote into the server and install these dependencies

### 1️⃣ Install K3S

Before installing K3s, set your node IP and cluster token:

```bash
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

---

### 2️⃣ Download Git Repo

```bash
git clone https://github.com/Aschonn/flux-homelab.git
```
---

### 3️⃣ Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

---

### 4️⃣ Configure kubectl Access



---

### 5️⃣ Helpful Tools

#### k9s (Kubernetes CLI UI)

```bash
curl -sS https://webinstall.dev/k9s | bash
source ~/.config/envman/PATH.env
```

---

### 6️⃣ Essential Packages

Install ZFS, NFS, iSCSI, and CIFS support:

```bash
sudo apt update && sudo apt install -y \
  zfsutils-linux \
  nfs-kernel-server \
  cifs-utils \
  open-iscsi  # Optional but recommended
```

---

### 7️⃣ ArgoCD CLI

Install ArgoCD CLI:

```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

---

## 🐞 Debug / Local Access

If you want to **debug the application without creating an ingress**, you can forward the ArgoCD server port to your node:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0
```

- Access via: `https://<node-ip>:8080` from your local network.

---

## ✅ Notes

- Ensure `SETUP_NODEIP` matches your node IP.  
- Use a strong `SETUP_CLUSTERTOKEN`.  
- Optional packages are recomm
