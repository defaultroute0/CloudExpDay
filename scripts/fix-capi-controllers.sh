#!/bin/bash
set -e

# Fix: CAPI errors after VKS version upgrade
# Use when VCFA cluster creation fails with:
#   "admission webhook capi.mutating.tanzukubernetescluster.run.tanzu.vmware.com denied the request"
#   "variable is not defined" for kubernetes, vmClass, storageClass
#
# This SSHes into vCenter → gets the Supervisor CP VM password → SSHes into the
# Supervisor CP VM → restarts the CAPI controllers to clear stale certs/cache.
#
# See: KB 392756, KB 423284, KB 424003

VCENTER_HOST="vc-wld01-a.vcf.lab"
VCENTER_USER="root"
VCENTER_PASS="VMware123!VMware123!"
SUPERVISOR_IP="10.1.0.6"
TKG_NAMESPACE="svc-tkg-domain-c10"

echo "=== Fix: Restart CAPI Controllers on Supervisor ==="
echo ""
echo "This fixes the 'variable is not defined' CAPI webhook error that occurs"
echo "after uploading a new VKS version (e.g., 3.4.0) to the Supervisor."
echo ""

# Check for sshpass
if ! command -v sshpass &> /dev/null; then
  echo "sshpass not found — falling through to manual instructions."
  echo ""
  echo "=== Manual Steps ==="
  echo ""
  echo "1. SSH into vCenter:"
  echo "   ssh root@${VCENTER_HOST}"
  echo "   Password: ${VCENTER_PASS}"
  echo "   Type 'shell' if you get the VCSA prompt"
  echo ""
  echo "2. Get the Supervisor CP VM password:"
  echo "   /usr/lib/vmware-wcp/decryptK8Pwd.py"
  echo "   → Note the PWD value"
  echo ""
  echo "3. SSH into the Supervisor CP VM:"
  echo "   ssh root@${SUPERVISOR_IP}"
  echo "   → Use the PWD from step 2"
  echo ""
  echo "4. Restart the controllers:"
  echo "   kubectl rollout restart deployment vmware-system-tkg-webhook -n ${TKG_NAMESPACE}"
  echo "   kubectl rollout restart deployment runtime-extension-controller-manager -n ${TKG_NAMESPACE}"
  echo "   kubectl rollout restart deployment capi-controller-manager -n ${TKG_NAMESPACE}"
  echo ""
  echo "5. Verify:"
  echo "   kubectl get deployments -n ${TKG_NAMESPACE}"
  echo "   kubectl describe clusterclass builtin-generic-v3.4.0 -n vmware-system-vks-public | grep VariablesReconciled"
  echo ""
  echo "To install sshpass and run this script automatically:"
  echo "  sudo apt install -y sshpass   # Debian/Ubuntu"
  echo "  brew install sshpass          # macOS"
  exit 1
fi

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

# Step 1: Get Supervisor CP VM password from vCenter
echo ">>> Retrieving Supervisor CP VM password from vCenter..."
SUP_PASSWORD=$(sshpass -p "${VCENTER_PASS}" ssh ${SSH_OPTS} ${VCENTER_USER}@${VCENTER_HOST} \
  "shell.set --enabled true 2>/dev/null; /usr/lib/vmware-wcp/decryptK8Pwd.py" 2>/dev/null \
  | grep "^PWD:" | head -1 | awk '{print $2}')

if [ -z "$SUP_PASSWORD" ]; then
  echo "ERROR: Could not retrieve Supervisor CP password."
  echo "Try manually: ssh root@${VCENTER_HOST} then run /usr/lib/vmware-wcp/decryptK8Pwd.py"
  exit 1
fi

echo "  Got password (${#SUP_PASSWORD} chars)"
echo ""

# Step 2: Restart controllers on the Supervisor CP VM
echo ">>> SSHing into Supervisor CP VM at ${SUPERVISOR_IP}..."
echo ">>> Restarting CAPI controllers in ${TKG_NAMESPACE}..."
echo ""

sshpass -p "${SUP_PASSWORD}" ssh ${SSH_OPTS} root@${SUPERVISOR_IP} bash -s <<REMOTE
echo "--- Restarting vmware-system-tkg-webhook ---"
kubectl rollout restart deployment vmware-system-tkg-webhook -n ${TKG_NAMESPACE}

echo "--- Restarting runtime-extension-controller-manager ---"
kubectl rollout restart deployment runtime-extension-controller-manager -n ${TKG_NAMESPACE}

echo "--- Restarting capi-controller-manager ---"
kubectl rollout restart deployment capi-controller-manager -n ${TKG_NAMESPACE}

echo ""
echo "--- Waiting for rollouts to complete ---"
kubectl rollout status deployment vmware-system-tkg-webhook -n ${TKG_NAMESPACE} --timeout=120s
kubectl rollout status deployment runtime-extension-controller-manager -n ${TKG_NAMESPACE} --timeout=120s
kubectl rollout status deployment capi-controller-manager -n ${TKG_NAMESPACE} --timeout=120s

echo ""
echo "--- Deployment status ---"
kubectl get deployments -n ${TKG_NAMESPACE}

echo ""
echo "--- ClusterClass reconciliation status ---"
kubectl get clusterclass -n vmware-system-vks-public 2>/dev/null || echo "(no clusterclass found yet)"
REMOTE

echo ""
echo "=== Fix Complete ==="
echo ""
echo "Retry creating the VKS cluster in VCFA now."
echo "If it still fails, wait 2-3 minutes for the webhook cache to fully refresh."
