#!/bin/bash
set -e

# Fix: CAPI errors after VKS version upgrade
# Use when VCFA cluster creation fails with:
#   "admission webhook capi.mutating.tanzukubernetescluster.run.tanzu.vmware.com denied the request"
#   "variable is not defined" for kubernetes, vmClass, storageClass
#
# This SSHes into the Supervisor CP VM and restarts the CAPI controllers
# to clear stale certs/cache.
#
# Usage:
#   ./fix-capi-controllers.sh                    # prompts for Supervisor CP password
#   SUP_PASSWORD='xyz' ./fix-capi-controllers.sh # skips prompt
#
# To get the Supervisor CP password:
#   ssh root@vc-wld01-a.vcf.lab  (password: VMware123!VMware123!)
#   Type: shell
#   Run:  /usr/lib/vmware-wcp/decryptK8Pwd.py
#   Copy the PWD value
#
# See: KB 392756, KB 423284, KB 424003

SUPERVISOR_IP="10.1.0.6"
TKG_NAMESPACE="svc-tkg-domain-c10"

echo "=== Fix: Restart CAPI Controllers on Supervisor ==="
echo ""
echo "This fixes the 'variable is not defined' CAPI webhook error that occurs"
echo "after uploading a new VKS version (e.g., 3.4.0) to the Supervisor."
echo ""

# Check for sshpass
if ! command -v sshpass &> /dev/null; then
  echo "sshpass not found. Install it first:"
  echo "  sudo apt install -y sshpass"
  echo ""
  echo "Or run the commands manually (see below)."
  echo ""
  echo "=== Manual Steps ==="
  echo ""
  echo "1. Get the Supervisor CP VM password from vCenter:"
  echo "   ssh root@vc-wld01-a.vcf.lab"
  echo "   Password: VMware123!VMware123!"
  echo "   Type: shell"
  echo "   Run:  /usr/lib/vmware-wcp/decryptK8Pwd.py"
  echo "   Note the PWD value"
  echo ""
  echo "2. SSH into the Supervisor CP VM:"
  echo "   ssh root@${SUPERVISOR_IP}"
  echo "   Use the PWD from step 1"
  echo ""
  echo "3. Run these commands:"
  echo "   kubectl rollout restart deployment vmware-system-tkg-webhook -n ${TKG_NAMESPACE}"
  echo "   kubectl rollout restart deployment runtime-extension-controller-manager -n ${TKG_NAMESPACE}"
  echo "   kubectl rollout restart deployment capi-controller-manager -n ${TKG_NAMESPACE}"
  echo "   kubectl get deployments -n ${TKG_NAMESPACE}"
  exit 1
fi

# Get the Supervisor CP VM password
if [ -z "$SUP_PASSWORD" ]; then
  echo "You need the Supervisor CP VM root password."
  echo "To get it, SSH into vCenter in another terminal:"
  echo ""
  echo "  ssh root@vc-wld01-a.vcf.lab"
  echo "  Password: VMware123!VMware123!"
  echo "  Type: shell"
  echo "  Run:  /usr/lib/vmware-wcp/decryptK8Pwd.py"
  echo "  Copy the PWD value"
  echo ""
  read -s -p "Paste the Supervisor CP VM password here: " SUP_PASSWORD
  echo ""
  echo ""
fi

if [ -z "$SUP_PASSWORD" ]; then
  echo "ERROR: No password provided."
  exit 1
fi

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

# Test SSH connectivity first
echo ">>> Testing SSH to Supervisor CP VM at ${SUPERVISOR_IP}..."
if ! sshpass -p "${SUP_PASSWORD}" ssh ${SSH_OPTS} root@${SUPERVISOR_IP} "echo ok" 2>/dev/null; then
  echo "ERROR: Cannot SSH into ${SUPERVISOR_IP}. Check the password."
  echo "Re-run /usr/lib/vmware-wcp/decryptK8Pwd.py on vCenter to get a fresh password."
  exit 1
fi
echo "  Connected."
echo ""

# Restart controllers on the Supervisor CP VM
echo ">>> Restarting CAPI controllers in ${TKG_NAMESPACE}..."
echo ""

sshpass -p "${SUP_PASSWORD}" ssh ${SSH_OPTS} root@${SUPERVISOR_IP} bash -s <<REMOTE
set -e

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
