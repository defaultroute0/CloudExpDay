#!/bin/bash
set -e

# Step 6: Create VCFA CLI Context
# Prerequisites: None (API token is pre-created)

# Auto-detect script directory and lab files location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="${LAB_DIR:-$(dirname "$SCRIPT_DIR")}"

# Find CA certificate (check ~, LAB_DIR, SCRIPT_DIR)
if [ -f ~/vcfa-cert-chain.pem ]; then
  CA_CERT=~/vcfa-cert-chain.pem
elif [ -f "$LAB_DIR/vcfa-cert-chain.pem" ]; then
  CA_CERT="$LAB_DIR/vcfa-cert-chain.pem"
elif [ -f "$SCRIPT_DIR/vcfa-cert-chain.pem" ]; then
  CA_CERT="$SCRIPT_DIR/vcfa-cert-chain.pem"
else
  echo "ERROR: Cannot find vcfa-cert-chain.pem"
  echo "Looked in: ~/, $LAB_DIR/, $SCRIPT_DIR/"
  echo "Download from VCFA UI or use --skip-tls-verify"
  exit 1
fi

echo "=== Step 6: Creating VCFA CLI Context ==="
echo "Using CA cert: $CA_CERT"
echo ""

cd "$LAB_DIR"

# Create context for VCF Automation
vcf context create vcfa \
  --endpoint auto-a.site-a.vcf.lab \
  --api-token 0lraViAN9alcyYTZ0KlAuqLqrvEqxsr3 \
  --tenant-name broadcom \
  --ca-certificate "$CA_CERT"

echo ""
echo "Context created. Available contexts:"
vcf context list

echo ""
echo "=== Step 6 Complete ==="
echo ""
echo "Next: Switch to your dev namespace with:"
echo "  vcf context use vcfa:<DEV_NS>:default-project"
echo ""
echo "Or run interactively:"
echo "  vcf context use"
