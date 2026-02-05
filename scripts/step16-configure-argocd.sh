#!/bin/bash
set -e

# Step 16: Configure ArgoCD and Register Clusters
# Prerequisites: ARGOCD_IP is set, TEST_NS is set, DEV_NS is set

if [ -z "$ARGOCD_IP" ]; then
  echo "ERROR: Set ARGOCD_IP first — export ARGOCD_IP=10.1.11.X"
  exit 1
fi

if [ -z "$TEST_NS" ]; then
  echo "ERROR: Set TEST_NS first — export TEST_NS=test-XXXXX"
  exit 1
fi

if [ -z "$DEV_NS" ]; then
  echo "ERROR: Set DEV_NS first — export DEV_NS=dev-XXXXX"
  exit 1
fi

echo "=== Step 16: Configure ArgoCD ==="
echo "ArgoCD IP: $ARGOCD_IP"
echo "Test NS: $TEST_NS"
echo "Dev NS: $DEV_NS"
echo ""

# Get initial password if not set
if [ -z "$ARGOCD_PASSWORD" ]; then
  echo ">>> Getting ArgoCD initial password..."
  vcf context use supervisor:$TEST_NS
  ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
fi

# Login to ArgoCD
echo ">>> Logging into ArgoCD CLI..."
argocd login $ARGOCD_IP --username admin --password "$ARGOCD_PASSWORD" --insecure

# Change password
echo ">>> Changing ArgoCD admin password..."
argocd account update-password \
  --current-password "$ARGOCD_PASSWORD" \
  --new-password 'VMware123!VMware123!'

echo "Password changed to: VMware123!VMware123!"

# Re-login with new password
argocd login $ARGOCD_IP --username admin --password 'VMware123!VMware123!' --insecure

# Register Supervisor as ArgoCD destination
echo ""
echo ">>> Registering Supervisor as ArgoCD cluster destination..."
argocd cluster add supervisor \
  --namespace $TEST_NS \
  --namespace $DEV_NS \
  --kubeconfig ~/.kube/config \
  --yes

echo ""
echo ">>> Registered clusters:"
argocd cluster list

echo ""
echo "=== Step 16 Complete ==="
echo ""
echo "Next:"
echo "1. Upload manifests to Gitea (see RUNBOOK.md Step 15)"
echo "2. Wait for test vks-01 to be Ready in VCFA"
echo "3. Download test vks-01 kubeconfig"
echo "4. Run ./step17-register-test-vks01.sh"
