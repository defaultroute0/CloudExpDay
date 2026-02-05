#!/bin/bash
set -e

# Step 17: Register test vks-01 in ArgoCD
# Prerequisites: ARGOCD_IP is set, test vks-01 kubeconfig downloaded to ~/Downloads/vks-01-kubeconfig.yaml

if [ -z "$ARGOCD_IP" ]; then
  echo "ERROR: Set ARGOCD_IP first — export ARGOCD_IP=10.1.11.X"
  exit 1
fi

KUBECONFIG_FILE="${VKS01_KUBECONFIG:-$HOME/Downloads/vks-01-kubeconfig.yaml}"

if [ ! -f "$KUBECONFIG_FILE" ]; then
  echo "ERROR: Kubeconfig not found at $KUBECONFIG_FILE"
  echo ""
  echo "Download it from VCFA:"
  echo "  Build & Deploy → test-XXXXX → Kubernetes → vks-01 → Download Kubeconfig"
  echo ""
  echo "Or set a custom path:"
  echo "  export VKS01_KUBECONFIG=/path/to/kubeconfig.yaml"
  exit 1
fi

echo "=== Step 17: Register test vks-01 in ArgoCD ==="
echo "ArgoCD IP: $ARGOCD_IP"
echo "Kubeconfig: $KUBECONFIG_FILE"
echo ""

cd ~/Downloads

# Login to ArgoCD
echo ">>> Logging into ArgoCD..."
argocd login $ARGOCD_IP --username admin --password 'VMware123!VMware123!' --insecure

# Get the context name from kubeconfig
CONTEXT_NAME=$(kubectl --kubeconfig "$KUBECONFIG_FILE" config current-context)
echo ">>> Found context: $CONTEXT_NAME"

# Register vks-01 cluster
echo ">>> Registering vks-01 in ArgoCD..."
argocd cluster add "$CONTEXT_NAME" \
  --name vks-01 \
  --kubeconfig "$KUBECONFIG_FILE" \
  --yes

echo ""
echo ">>> Registered clusters:"
argocd cluster list

echo ""
echo "=== Step 17 Complete ==="
echo ""
echo "Next:"
echo "1. Edit opencart.yaml in Gitea with correct IPs"
echo "2. Run ./step19-create-argocd-apps.sh"
