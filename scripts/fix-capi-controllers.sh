#!/bin/bash

# Fix: CAPI errors after VKS version upgrade
# Use when VCFA cluster creation fails with:
#   "admission webhook capi.mutating.tanzukubernetescluster.run.tanzu.vmware.com denied the request"
#   "variable is not defined" for kubernetes, vmClass, storageClass
#
# Strategy:
#   1. Try kubectl from current Supervisor context (may work if admin has sufficient RBAC)
#   2. If permission denied, SSH into a Supervisor CP VM and run from there
#
# The Supervisor API VIP (10.1.0.6) does NOT accept SSH — only port 443.
# SSH must target the individual CP VM management IPs (discovered from kubectl get nodes).
#
# See: KB 392756, KB 423284, KB 424003

TKG_NAMESPACE="svc-tkg-domain-c10"
SUP_PASSWORD='rAV&C[D=z|9>?iNC'
SUP_CP_VMS="10.1.1.86 10.1.1.87 10.1.1.88"

RESTART_CMDS="kubectl rollout restart deployment vmware-system-tkg-webhook -n ${TKG_NAMESPACE} && \
kubectl rollout restart deployment runtime-extension-controller-manager -n ${TKG_NAMESPACE} && \
kubectl rollout restart deployment capi-controller-manager -n ${TKG_NAMESPACE}"

WAIT_CMDS="kubectl rollout status deployment vmware-system-tkg-webhook -n ${TKG_NAMESPACE} --timeout=120s && \
kubectl rollout status deployment runtime-extension-controller-manager -n ${TKG_NAMESPACE} --timeout=120s && \
kubectl rollout status deployment capi-controller-manager -n ${TKG_NAMESPACE} --timeout=120s"

VERIFY_CMDS="kubectl get deployments -n ${TKG_NAMESPACE} && echo '' && \
kubectl get clusterclass -n vmware-system-vks-public 2>/dev/null || true"

echo "=== Fix: Restart CAPI Controllers on Supervisor ==="
echo ""
echo "This fixes the 'variable is not defined' CAPI webhook error that occurs"
echo "after uploading a new VKS version (e.g., 3.4.0) to the Supervisor."
echo ""

# ── Method 1: Try kubectl directly from current context ─────────────
# This works if the current Supervisor context has access to the svc-tkg namespace.
echo ">>> Method 1: Trying kubectl from current context..."
if kubectl get deployment -n "${TKG_NAMESPACE}" vmware-system-tkg-webhook &>/dev/null; then
  echo "  Access to ${TKG_NAMESPACE} confirmed — restarting controllers..."
  echo ""

  eval "${RESTART_CMDS}"

  echo ""
  echo "--- Waiting for rollouts to complete ---"
  eval "${WAIT_CMDS}"

  echo ""
  echo "--- Verification ---"
  eval "${VERIFY_CMDS}"

  echo ""
  echo "=== Fix Complete ==="
  echo ""
  echo "Retry creating the VKS cluster in VCFA now."
  echo "If it still fails, wait 2-3 minutes for the webhook cache to fully refresh."
  exit 0
fi

echo "  No access from current context (expected). Falling back to SSH..."
echo ""

# ── Method 2: SSH into a Supervisor CP VM ────────────────────────────
# The API VIP (10.1.0.6) only serves port 443, not SSH.
# We need the individual CP VM IPs from kubectl get nodes.

if ! command -v sshpass &>/dev/null; then
  echo ">>> Installing sshpass..."
  sudo apt install -y sshpass
  echo ""
fi

echo ">>> Supervisor CP VM IPs: ${SUP_CP_VMS}"
echo ""

export SSHPASS="${SUP_PASSWORD}"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAuthentication=no -o PreferredAuthentications=password,keyboard-interactive -o ConnectTimeout=10"

# Try each node IP until one accepts SSH
CONNECTED=""
for IP in ${SUP_CP_VMS}; do
  echo ">>> Trying SSH to ${IP}..."
  if sshpass -e ssh ${SSH_OPTS} root@"${IP}" "echo ok" 2>/dev/null; then
    CONNECTED="${IP}"
    echo "  Connected to ${IP}."
    break
  else
    echo "  ${IP} — SSH failed, trying next..."
  fi
done

if [ -z "$CONNECTED" ]; then
  echo ""
  echo "ERROR: Could not SSH into any Supervisor CP VM."
  echo ""
  echo "SSH may be disabled on the CP VMs. Manual fix via vCenter Console:"
  echo ""
  echo "  1. In vCenter: Hosts and Clusters → find a SupervisorControlPlaneVM"
  echo "  2. Open Console (Launch Web Console)"
  echo "  3. Login: root / ${SUP_PASSWORD}"
  echo "  4. Run:"
  echo "     kubectl rollout restart deployment vmware-system-tkg-webhook -n ${TKG_NAMESPACE}"
  echo "     kubectl rollout restart deployment runtime-extension-controller-manager -n ${TKG_NAMESPACE}"
  echo "     kubectl rollout restart deployment capi-controller-manager -n ${TKG_NAMESPACE}"
  echo "     kubectl get deployments -n ${TKG_NAMESPACE}"
  exit 1
fi

echo ""
echo ">>> Restarting CAPI controllers via ${CONNECTED}..."
echo ""

sshpass -e ssh ${SSH_OPTS} root@"${CONNECTED}" \
  "${RESTART_CMDS} && echo '' && echo '--- Waiting for rollouts ---' && ${WAIT_CMDS} && echo '' && echo '--- Verification ---' && ${VERIFY_CMDS}"

echo ""
echo "=== Fix Complete ==="
echo ""
echo "Retry creating the VKS cluster in VCFA now."
echo "If it still fails, wait 2-3 minutes for the webhook cache to fully refresh."
