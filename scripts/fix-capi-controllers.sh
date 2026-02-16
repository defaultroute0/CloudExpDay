#!/bin/bash
set -e

# Fix: CAPI errors after VKS version upgrade
# Use when VCFA cluster creation fails with:
#   "admission webhook capi.mutating.tanzukubernetescluster.run.tanzu.vmware.com denied the request"
#   "variable is not defined" for kubernetes, vmClass, storageClass
#
# Fully automated: SSHes into vCenter (handles appliancesh via expect),
# retrieves the Supervisor CP VM password, SSHes into the CP VM,
# and restarts the CAPI controllers.
#
# See: KB 392756, KB 423284, KB 424003

VCENTER_HOST="vc-wld01-a.vcf.lab"
VCENTER_PASS='VMware123!VMware123!'
SUPERVISOR_IP="10.1.0.6"
TKG_NAMESPACE="svc-tkg-domain-c10"

echo "=== Fix: Restart CAPI Controllers on Supervisor ==="
echo ""
echo "This fixes the 'variable is not defined' CAPI webhook error that occurs"
echo "after uploading a new VKS version (e.g., 3.4.0) to the Supervisor."
echo ""

# Install dependencies if needed
MISSING=""
command -v sshpass &>/dev/null || MISSING="sshpass $MISSING"
command -v expect &>/dev/null || MISSING="expect $MISSING"

if [ -n "$MISSING" ]; then
  echo ">>> Installing missing dependencies: ${MISSING}..."
  sudo apt install -y $MISSING
  echo ""
fi

# Step 1: Get Supervisor CP VM password from vCenter
# The VCSA uses appliancesh as the default login shell for root.
# Non-interactive SSH commands don't reach bash. We use expect to:
#   1. SSH in and land at the appliancesh "Command>" prompt
#   2. Type "shell" to drop into bash
#   3. Run decryptK8Pwd.py and capture the output
echo ">>> Retrieving Supervisor CP VM password from vCenter..."

DECRYPT_OUTPUT=$(expect 2>/dev/null <<'EXPECT_BLOCK'
set timeout 30
log_user 0

spawn sshpass -p {VMware123!VMware123!} ssh \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o LogLevel=ERROR \
  root@vc-wld01-a.vcf.lab

# VCSA may drop us into appliancesh ("Command>") or bash ("#")
expect {
  "Command>" {
    send "shell\r"
    expect "$ " {} "#" {}
  }
  "# " {}
  "$ " {}
}

# Disable terminal escape codes that would pollute our output
send "export TERM=dumb\r"
expect "# " {} "$ " {}

# Run the decrypt script — turn log_user ON so output is captured in stdout
log_user 1
send "/usr/lib/vmware-wcp/decryptK8Pwd.py\r"
expect "# " {} "$ " {}
log_user 0

# Clean exit: bash → appliancesh → disconnect
send "exit\r"
send "exit\r"
expect eof
EXPECT_BLOCK
) || true

# Parse the password from decryptK8Pwd.py output
# Output format:  PWD: <password>
# Strip ANSI escapes, find PWD line, extract value
SUP_PASSWORD=$(echo "$DECRYPT_OUTPUT" | sed 's/\x1b\[[0-9;]*m//g' | grep "PWD:" | head -1 | sed 's/.*PWD: *//' | tr -d '[:space:]')

if [ -z "$SUP_PASSWORD" ]; then
  echo "WARNING: Could not retrieve password automatically."
  echo ""
  echo "Debug output:"
  echo "$DECRYPT_OUTPUT" | head -20
  echo ""
  echo "Get it manually in another terminal:"
  echo "  ssh root@${VCENTER_HOST}   (password: ${VCENTER_PASS})"
  echo "  Type: shell"
  echo "  Run:  /usr/lib/vmware-wcp/decryptK8Pwd.py"
  echo "  Copy the PWD value"
  echo ""
  read -s -p "Paste the Supervisor CP VM password here: " SUP_PASSWORD
  echo ""
  echo ""
  if [ -z "$SUP_PASSWORD" ]; then
    echo "ERROR: No password provided."
    exit 1
  fi
fi

echo "  Got password (${#SUP_PASSWORD} chars)"
echo ""

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

# Step 2: Test SSH to Supervisor CP VM
echo ">>> Testing SSH to Supervisor CP VM at ${SUPERVISOR_IP}..."
if ! sshpass -p "${SUP_PASSWORD}" ssh ${SSH_OPTS} root@${SUPERVISOR_IP} "echo ok" 2>/dev/null; then
  echo "ERROR: Cannot SSH into ${SUPERVISOR_IP}. Password may be wrong."
  echo "Re-run /usr/lib/vmware-wcp/decryptK8Pwd.py on vCenter to verify."
  exit 1
fi
echo "  Connected."
echo ""

# Step 3: Restart controllers on the Supervisor CP VM
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
