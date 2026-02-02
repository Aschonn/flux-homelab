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

Clone this repo and run the bootstrap script:

```bash
chmod +x setup-homelab.sh
./setup-homelab.sh
```

### Helpful Tools

#### k9s (Kubernetes CLI UI)

```bash
curl -sS https://webinstall.dev/k9s | bash
source ~/.config/envman/PATH.env
```

