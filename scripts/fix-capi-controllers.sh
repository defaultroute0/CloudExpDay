#!/bin/bash
set -e

# Fix: CAPI errors after VKS version upgrade
# Use when VCFA cluster creation fails with:
#   "admission webhook capi.mutating.tanzukubernetescluster.run.tanzu.vmware.com denied the request"
#   "variable is not defined" for kubernetes, vmClass, storageClass
#
# SSHes directly into the Supervisor CP VM and restarts the CAPI controllers
# to clear stale certs/webhook cache.
#
# See: KB 392756, KB 423284, KB 424003

SUPERVISOR_IP="10.1.0.6"
SUP_PASSWORD='rAV&C[D=z|9>?iNC'
TKG_NAMESPACE="svc-tkg-domain-c10"

echo "=== Fix: Restart CAPI Controllers on Supervisor ==="
echo ""
echo "This fixes the 'variable is not defined' CAPI webhook error that occurs"
echo "after uploading a new VKS version (e.g., 3.4.0) to the Supervisor."
echo ""

# Install sshpass if needed
if ! command -v sshpass &>/dev/null; then
  echo ">>> Installing sshpass..."
  sudo apt install -y sshpass
  echo ""
fi

# Use SSHPASS env var instead of -p flag to avoid shell metacharacter issues
# Force password auth — Supervisor CP VM may use keyboard-interactive
export SSHPASS="${SUP_PASSWORD}"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o PubkeyAuthentication=no -o PreferredAuthentications=password,keyboard-interactive"

# Test SSH connectivity
echo ">>> Connecting to Supervisor CP VM at ${SUPERVISOR_IP}..."
SSH_OUTPUT=$(sshpass -e ssh ${SSH_OPTS} root@${SUPERVISOR_IP} "echo ok" 2>&1) || {
  echo "ERROR: Cannot SSH into ${SUPERVISOR_IP}."
  echo ""
  echo "SSH output:"
  echo "$SSH_OUTPUT"
  echo ""
  echo "sshpass exit code meanings:"
  echo "  1 = Invalid arguments"
  echo "  2 = Conflicting arguments"
  echo "  3 = General runtime error"
  echo "  5 = Invalid/incorrect password"
  echo "  6 = Host public key is unknown (shouldn't happen with our SSH_OPTS)"
  echo ""
  echo "If password is wrong, retrieve from vCenter:"
  echo "  ssh root@vc-wld01-a.vcf.lab   (password: VMware123!VMware123!)"
  echo "  Type: shell"
  echo "  Run:  /usr/lib/vmware-wcp/decryptK8Pwd.py"
  exit 1
}
echo "  Connected."
echo ""

# Restart controllers
echo ">>> Restarting CAPI controllers in ${TKG_NAMESPACE}..."
echo ""

sshpass -e ssh ${SSH_OPTS} root@${SUPERVISOR_IP} bash -s <<REMOTE
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
