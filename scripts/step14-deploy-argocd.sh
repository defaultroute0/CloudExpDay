#!/bin/bash
set -e

# Step 14: Deploy ArgoCD
# Prerequisites: TEST_NS is set

if [ -z "$TEST_NS" ]; then
  echo "ERROR: Set TEST_NS first — export TEST_NS=test-XXXXX"
  exit 1
fi

echo "=== Step 14: Deploy ArgoCD ==="
echo "Namespace: $TEST_NS"
echo ""

cd ~/Documents/Lab

# Create supervisor context
echo ">>> Creating supervisor context..."
vcf context create supervisor \
  --endpoint 10.1.0.6 \
  --username administrator@wld.sso \
  --insecure-skip-tls-verify \
  --auth-type basic <<< "VMware123!VMware123!"

# Switch to test namespace
echo ">>> Switching to test namespace..."
vcf context use supervisor:$TEST_NS

# Deploy ArgoCD
echo ">>> Deploying ArgoCD instance..."
kubectl apply -f argocd-instance.yaml

# Wait for pods
echo ""
echo ">>> Waiting for ArgoCD pods (this may take 3-5 minutes)..."
echo ">>> If pods stay Pending, increase CPU limit in VCA:"
echo "    Menu → Workload Management → Namespaces → $TEST_NS → Configure → CPU: 25 GHz"
echo ""

ATTEMPT=0
MAX_ATTEMPTS=60  # 5 minutes

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  READY=$(kubectl get pods 2>/dev/null | grep -c "Running" || echo "0")
  PENDING=$(kubectl get pods 2>/dev/null | grep -c "Pending" || echo "0")
  TOTAL=$(kubectl get pods 2>/dev/null | grep -v "NAME" | wc -l | tr -d ' ' || echo "0")

  echo "  Pods: $READY running, $PENDING pending, $TOTAL total"

  if [ "$READY" -gt 0 ] && [ "$PENDING" -eq 0 ] && [ "$TOTAL" -gt 0 ]; then
    echo ""
    echo "ArgoCD pods are running!"
    break
  fi

  ATTEMPT=$((ATTEMPT + 1))
  sleep 5
done

echo ""
kubectl get pods

# Get ArgoCD password
echo ""
echo ">>> Retrieving ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
echo "Initial admin password: $ARGOCD_PASSWORD"

# Get ArgoCD IP
echo ""
echo ">>> Getting ArgoCD external IP..."
ARGOCD_IP=$(kubectl get svc argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
echo "ArgoCD IP: $ARGOCD_IP"

echo ""
echo "=== Step 14 Complete ==="
echo ""
echo "ArgoCD URL: https://$ARGOCD_IP"
echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD"
echo ""
echo "Export for later steps:"
echo "  export ARGOCD_IP=$ARGOCD_IP"
echo "  export ARGOCD_PASSWORD='$ARGOCD_PASSWORD'"
