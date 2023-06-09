# Vechr App

Vechr app is application IIoT for manufacturing, and running on kubernetes Cluster, Vechr can run on premises, cloud as long as having kubernetes cluster.

## TL;DR;
```bash
# Install Cert Manager first (if needed)
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.11.0 \
  --set installCRDs=true

# Install vechr
helm repo add vechr https://vechr.github.io/vechr-atlas/helm/charts/
helm repo update
helm install vechr-production vechr/vechr-iiot
```