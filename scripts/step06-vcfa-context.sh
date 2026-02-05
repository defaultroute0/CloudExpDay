#!/bin/bash
set -e

# Step 6: Create VCFA CLI Context
# Prerequisites: None (API token is pre-created)

echo "=== Step 6: Creating VCFA CLI Context ==="

cd ~/Documents/Lab

# Create context for VCF Automation
vcf context create vcfa \
  --endpoint auto-a.site-a.vcf.lab \
  --api-token 0lraViAN9alcyYTZ0KlAuqLqrvEqxsr3 \
  --tenant-name broadcom \
  --ca-certificate vcfa-cert-chain.pem

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
