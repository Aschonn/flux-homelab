kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token=SSJaPxlY3PXgHeUYGECvQxEDmt464mv5l59Al0Mr \
  --namespace cert-manager \
  --dry-run=client -o yaml > cloudflare-api-token.yaml

# install crds
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.crds.yaml
