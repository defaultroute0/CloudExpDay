#!/bin/bash
set -e

# Step 11: Configure vks-01 and Deploy OpenCart
# Prerequisites: DEV_NS is set, vks-01 is Ready, MYSQL_LB_IP is set

if [ -z "$DEV_NS" ]; then
  echo "ERROR: Set DEV_NS first — export DEV_NS=dev-XXXXX"
  exit 1
fi

if [ -z "$MYSQL_LB_IP" ]; then
  echo "ERROR: Set MYSQL_LB_IP first — export MYSQL_LB_IP=X.X.X.X"
  echo "(Get this from VCFA Network Service for oc-mysql VM)"
  exit 1
fi

echo "=== Step 11: Configure vks-01 and Deploy OpenCart ==="
echo "Namespace: $DEV_NS"
echo "MySQL LB IP: $MYSQL_LB_IP"
echo ""

cd ~/Documents/Lab

# Ensure we're in the right context
vcf context use vcfa:$DEV_NS:default-project

# Register JWT authenticator for vks-01
echo ">>> Registering VCFA JWT authenticator for vks-01..."
vcf cluster register-vcfa-jwt-authenticator vks-01

# Export kubeconfig
echo ">>> Exporting vks-01 kubeconfig..."
vcf cluster kubeconfig get vks-01 --export-file ~/.kube/config

# Get the kubecontext name
KUBECONTEXT=$(cat ~/.kube/config | grep -o 'vcf-cli-vks-01-[^@]*@vks-01-[^ ]*' | head -1)
echo ">>> Found kubecontext: $KUBECONTEXT"

# Create VCF context for vks-01
echo ">>> Creating VCF context for vks-01..."
vcf context create vks-01 \
  --kubeconfig ~/.kube/config \
  --kubecontext "$KUBECONTEXT"

# Refresh and switch to vks-01
vcf context refresh
vcf context use vks-01

# Verify nodes are ready
echo ">>> Waiting for vks-01 nodes to be Ready..."
kubectl wait --for=condition=Ready node --all --timeout=300s

echo ""
kubectl get nodes
echo ""

# Add package repository
echo ">>> Adding VKS Standard Packages repository..."
vcf package repository add default-repo \
  --url projects.packages.broadcom.com/vsphere/supervisor/packages/2025.8.19/vks-standard-packages:v2025.8.19 \
  -n tkg-system

# List available packages
echo ""
echo ">>> Available packages:"
vcf package available list -n tkg-system

# Create namespaces
echo ""
echo ">>> Creating namespaces..."
kubectl create ns prometheus-installed --dry-run=client -o yaml | kubectl apply -f -
kubectl create ns telegraf-installed --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace opencart --dry-run=client -o yaml | kubectl apply -f -
kubectl label ns opencart pod-security.kubernetes.io/enforce=privileged --overwrite

# Install Prometheus
echo ""
echo ">>> Installing Prometheus..."
vcf package install prometheus \
  -p prometheus.kubernetes.vmware.com \
  --values-file prometheus-data-values.yaml \
  -n prometheus-installed \
  -v 3.5.0+vmware.1-vks.1 || echo "Prometheus may already be installed"

# Install Telegraf
echo ""
echo ">>> Installing Telegraf..."
vcf package install telegraf \
  -p telegraf.kubernetes.vmware.com \
  --values-file telegraf-data-values.yaml \
  -n telegraf-installed \
  -v 1.34.4+vmware.2-vks.1 || echo "Telegraf may already be installed"

# Deploy OpenCart LB
echo ""
echo ">>> Deploying OpenCart Load Balancer..."
kubectl apply -f opencart-lb.yaml -n opencart

# Wait for external IP
echo ""
echo ">>> Waiting for OpenCart LB external IP..."
while true; do
  OPENCART_LB_IP=$(kubectl get svc -n opencart my-open-cart-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
  if [ -n "$OPENCART_LB_IP" ] && [ "$OPENCART_LB_IP" != "<pending>" ]; then
    break
  fi
  echo "  Waiting for external IP..."
  sleep 5
done

echo ""
echo "OpenCart LB IP: $OPENCART_LB_IP"

# Update opencart.yaml with IPs
echo ""
echo ">>> Updating opencart.yaml with IPs..."
sed -i.bak "s/OPENCART_DATABASE_HOST:.*/OPENCART_DATABASE_HOST: \"$MYSQL_LB_IP\"/" opencart.yaml
sed -i.bak "s/OPENCART_HOST:.*/OPENCART_HOST: \"$OPENCART_LB_IP\"/" opencart.yaml

# Deploy OpenCart application
echo ""
echo ">>> Deploying OpenCart application..."
kubectl apply -f opencart.yaml -n opencart

# Wait for pods
echo ""
echo ">>> Waiting for OpenCart pods..."
kubectl wait --for=condition=Ready pod -l app=my-open-cart -n opencart --timeout=300s || echo "Waiting for pods..."

echo ""
echo ">>> OpenCart deployment status:"
kubectl get all -n opencart

echo ""
echo "=== Step 11 Complete ==="
echo ""
echo "OpenCart LB IP: $OPENCART_LB_IP"
echo ""
echo "Access the application: http://$OPENCART_LB_IP"
echo ""
echo "Export for later steps:"
echo "  export OPENCART_LB_IP=$OPENCART_LB_IP"
