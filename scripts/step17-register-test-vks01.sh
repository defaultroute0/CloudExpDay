#!/bin/bash
set -e

# Step 17: Register test vks-01 in ArgoCD
# Prerequisites: ARGOCD_IP is set, test vks-01 kubeconfig downloaded

# Auto-detect script directory and lab files location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="${LAB_DIR:-$(dirname "$SCRIPT_DIR")}"

if [ -z "$ARGOCD_IP" ]; then
  echo "ERROR: Set ARGOCD_IP first — export ARGOCD_IP=10.1.11.X"
  exit 1
fi

# Look for kubeconfig in multiple locations
if [ -n "$VKS01_KUBECONFIG" ] && [ -f "$VKS01_KUBECONFIG" ]; then
  KUBECONFIG_FILE="$VKS01_KUBECONFIG"
elif [ -f "$HOME/Downloads/vks-01-kubeconfig.yaml" ]; then
  KUBECONFIG_FILE="$HOME/Downloads/vks-01-kubeconfig.yaml"
elif [ -f "$LAB_DIR/vks-01-kubeconfig.yaml" ]; then
  KUBECONFIG_FILE="$LAB_DIR/vks-01-kubeconfig.yaml"
else
  echo "ERROR: Kubeconfig not found"
  echo ""
  echo "Looked in:"
  echo "  - \$VKS01_KUBECONFIG (if set)"
  echo "  - ~/Downloads/vks-01-kubeconfig.yaml"
  echo "  - $LAB_DIR/vks-01-kubeconfig.yaml"
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

cd "$LAB_DIR"

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
