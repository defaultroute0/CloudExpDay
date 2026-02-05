#!/bin/bash
set -e

# Step 9: Push OpenCart Image to Harbor
# Prerequisites: Harbor is accessible, Docker is running

echo "=== Step 9: Pushing OpenCart Image to Harbor ==="

# Login to Harbor
echo ">>> Logging into Harbor..."
echo "Harbor12345" | docker login harbor-01a.site-a.vcf.lab -u admin --password-stdin

# Tag the image
echo ">>> Tagging OpenCart image..."
docker tag vcf-automation-docker-dev-local.usw5.packages.broadcom.com/bitnami/opencart:4.0.1-1-debian-11-r66 \
  harbor-01a.site-a.vcf.lab/opencart/opencart:4.0.1-1-debian-11-r66

# Push to Harbor
echo ">>> Pushing to Harbor (this may take a minute)..."
docker push harbor-01a.site-a.vcf.lab/opencart/opencart:4.0.1-1-debian-11-r66

echo ""
echo "=== Step 9 Complete ==="
echo ""
echo "Verify image in Harbor UI: https://harbor-01a.site-a.vcf.lab"
echo "Project: opencart"
