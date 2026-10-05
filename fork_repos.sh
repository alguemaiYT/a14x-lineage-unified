#!/usr/bin/env bash
# Automated fork script for a14x LineageOS 23.2 stack
set -euo pipefail

TARGET_ORG="devhunter1"
REPOS=(
  "local_manifests"
  "android_device_samsung_a14x"
  "android_device_samsung_s5e8535-common"
  "android_vendor_samsung_a14x"
  "android_vendor_samsung_s5e8535-common"
  "android_kernel_samsung_s5e8535"
  "android_hardware_samsung_slsi-linaro_graphics"
  "android_hardware_samsung_slsi-linaro_config"
  "android_hardware_samsung_slsi-linaro_exynos"
  "android_device_samsung_slsi_sepolicy"
)

echo "Verifying gh authentication..."
gh auth status

for repo in "${REPOS[@]}"; do
  echo "Forking ${TARGET_ORG}/${repo}..."
  gh repo fork "${TARGET_ORG}/${repo}" --clone=false || true
done

echo "Forking complete."
echo "CRITICAL: Stop this Codespace immediately if no further edits are needed to avoid quota consumption:"
echo "  gh codespace stop -c \$CODESPACE_NAME"
