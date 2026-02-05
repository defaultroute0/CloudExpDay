#!/bin/bash
set -e

# Step 19: Create ArgoCD Applications
# Prerequisites: ARGOCD_IP is set, manifests uploaded to Gitea, opencart.yaml updated with IPs

if [ -z "$ARGOCD_IP" ]; then
  echo "ERROR: Set ARGOCD_IP first — export ARGOCD_IP=10.1.11.X"
  exit 1
fi

echo "=== Step 19: Create ArgoCD Applications ==="
echo "ArgoCD IP: $ARGOCD_IP"
echo ""

cd ~/Documents/Lab

# Login to ArgoCD
echo ">>> Logging into ArgoCD..."
argocd login $ARGOCD_IP --username admin --password 'VMware123!VMware123!' --insecure

# Create opencart-lb application
echo ">>> Creating opencart-lb application..."
argocd app create opencart-lb --file argo-opencart-lb.yaml

# Check status
echo ""
echo ">>> opencart-lb status:"
argocd app get opencart-lb

# Create opencart-app application
echo ""
echo ">>> Creating opencart-app application..."
argocd app create opencart-app --file argo-opencart-app.yaml

# Check status
echo ""
echo ">>> opencart-app status:"
argocd app get opencart-app

# List all apps
echo ""
echo ">>> All ArgoCD applications:"
argocd app list

echo ""
echo "=== Step 19 Complete ==="
echo ""
echo "ArgoCD UI: https://$ARGOCD_IP"
echo ""
echo "Verify:"
echo "1. All apps show Healthy in ArgoCD UI"
echo "2. Access OpenCart via the opencart-lb service IP"
echo ""
echo "GitOps Demo:"
echo "1. Edit vks-01.yaml in Gitea (argocd/opencart-infra)"
echo "2. Change worker replicas: 1 → 2"
echo "3. Watch ArgoCD auto-sync"
