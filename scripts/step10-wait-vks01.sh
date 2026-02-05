#!/bin/bash
set -e

# Step 10: Wait for vks-01 to be Ready
# Prerequisites: DEV_NS is set, VCFA context exists

if [ -z "$DEV_NS" ]; then
  echo "ERROR: Set DEV_NS first — export DEV_NS=dev-XXXXX"
  exit 1
fi

echo "=== Step 10: Waiting for vks-01 Cluster ==="
echo "Namespace: $DEV_NS"
echo ""

# Switch to dev namespace context
vcf context use vcfa:$DEV_NS:default-project

echo ">>> Polling cluster status (this takes 15-20 minutes)..."
echo ""

while true; do
  # Get cluster status
  STATUS=$(vcf cluster list 2>/dev/null | grep vks-01 | awk '{print $2}' || echo "NotFound")

  if [ "$STATUS" = "Ready" ]; then
    echo ""
    echo "vks-01 is Ready!"
    break
  fi

  echo "  Cluster status: $STATUS — waiting 30s..."
  sleep 30
done

echo ""
vcf cluster list

echo ""
echo "=== Step 10 Complete ==="
echo ""
echo "Next: Run ./step11-configure-vks01.sh"
