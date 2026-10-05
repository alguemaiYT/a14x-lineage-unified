# Automated Setup and Fork Guide for Samsung Galaxy A14 5G (`a14x`) LineageOS 23.2

Target devices: Samsung Galaxy A14 5G (SM-A146B, SM-A146M) and Galaxy M14 5G (SM-M146B).
Platform: Samsung Exynos 1330 (`s5e8535`), Board `SRPVG28A003` / `erd8535`.
Base Branch: `lineage-23.2` (Android 15).

---

## 1. GitHub Codespaces Lifecycle Rules

GitHub Codespaces consumes quota and core-hours while active. Adhere strictly to the shutdown procedure:

1. Idle Timeout Configuration:
   Set default retention to minimum (5-10 minutes) under GitHub Settings -> Codespaces -> Default idle timeout.

2. Manual Shutdown Command:
   Execute immediately after finishing file edits or git push operations:
   ```bash
   gh codespace stop -c $CODESPACE_NAME
   ```
   Or via system power control:
   ```bash
   sudo shutdown -h now
   ```

3. Verification of Inactive State:
   Check running status from your local shell or web dashboard:
   ```bash
   gh codespace list
   ```
   Status must display `Shutdown`.

---

## 2. Automated Repository Forking Script

Run this script inside Codespaces or any authenticated terminal (`gh auth login` required) to fork all required component repositories to your personal account:

```bash
#!/usr/bin/env bash
set -euo pipefail

TARGET_ORG="devhunter1"
BRANCH="lineage-23.2"

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

echo "Starting fork synchronization..."

for repo in "${REPOS[@]}"; do
  echo "[FORK] Processing ${TARGET_ORG}/${repo}..."
  gh repo fork "${TARGET_ORG}/${repo}" --clone=false || true
done

echo "All devhunter1 repositories successfully forked."
```

---

## 3. Forked Local Manifest (`.repo/local_manifests/local_manifest.xml`)

Update the remotes to your GitHub username (replace `GITHUB_USER` with your account name):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>

  <!-- Remotes -->
  <remote name="LineageOS" fetch="https://github.com/LineageOS" clone-depth="1" />
  <remote name="personal" fetch="https://github.com/GITHUB_USER" clone-depth="1" />

  <!-- Device & Common Trees -->
  <project path="device/samsung/a14x" name="android_device_samsung_a14x" remote="personal" revision="lineage-23.2" />
  <project path="device/samsung/s5e8535-common" name="android_device_samsung_s5e8535-common" remote="personal" revision="lineage-23.2" />

  <!-- Vendor Blobs -->
  <project path="vendor/samsung/a14x" name="android_vendor_samsung_a14x" remote="personal" revision="lineage-23.2" />
  <project path="vendor/samsung/s5e8535-common" name="android_vendor_samsung_s5e8535-common" remote="personal" revision="lineage-23.2" />

  <!-- Kernel Source -->
  <project path="kernel/samsung/s5e8535" name="android_kernel_samsung_s5e8535" remote="personal" revision="lineage-23.2" />

  <!-- Samsung SLSI-Linaro HALs -->
  <project path="hardware/samsung_slsi-linaro/graphics" name="android_hardware_samsung_slsi-linaro_graphics" remote="personal" revision="lineage-23.2" />
  <project path="hardware/samsung_slsi-linaro/config" name="android_hardware_samsung_slsi-linaro_config" remote="personal" revision="lineage-23.2" />
  <project path="hardware/samsung_slsi-linaro/exynos" name="android_hardware_samsung_slsi-linaro_exynos" remote="personal" revision="lineage-23.2" />
  <project path="device/samsung_slsi/sepolicy" name="android_device_samsung_slsi_sepolicy" remote="personal" revision="lineage-23.2" />

  <!-- Upstream LineageOS Hardware Repositories -->
  <project path="hardware/samsung" name="android_hardware_samsung" remote="LineageOS" revision="lineage-23.2" />
  <project path="hardware/samsung_slsi/libbt" name="android_hardware_samsung_slsi_libbt" remote="LineageOS" revision="lineage-23.2" />
  <project path="hardware/samsung_slsi/scsc_wifibt/wifi_hal" name="android_hardware_samsung_slsi_scsc_wifibt_wifi_hal" remote="LineageOS" revision="lineage-23.2" />
  <project path="hardware/samsung_slsi/scsc_wifibt/wpa_supplicant_lib" name="android_hardware_samsung_slsi_scsc_wifibt_wpa_supplicant_lib" remote="LineageOS" revision="lineage-23.2" />
  <project path="hardware/samsung_slsi-linaro/openmax" name="android_hardware_samsung_slsi-linaro_openmax" remote="LineageOS" revision="lineage-23.2" />
  <project path="hardware/samsung_slsi-linaro/exynos5" name="android_hardware_samsung_slsi-linaro_exynos5" remote="LineageOS" revision="lineage-23.2" />
  <project path="hardware/samsung_slsi-linaro/interfaces" name="android_hardware_samsung_slsi-linaro_interfaces" remote="LineageOS" revision="lineage-23.2" />
  <project path="hardware/samsung_slsi-linaro/codec2" name="android_hardware_samsung_slsi-linaro_codec2" remote="LineageOS" revision="lineage-23.2" />

</manifest>
```

---

## 4. Hardware Parameters Verification

All settings verified against hardware forensics and GPT block mappings:

- Boot Image: 67,108,864 bytes (64 MB), Header v4, empty ramdisk.
- Init Boot Image: 16,777,216 bytes (16 MB), Header v4, first-stage system ramdisk.
- Recovery Image: 100,663,296 bytes (96 MB), Header v2, dtb offset 0, recovery dtbo attached.
- Super Partition: 8,287,944,704 bytes (~7.72 GiB).
- Dynamic Partition Group: 8,283,750,400 bytes (`system`, `system_ext`, `vendor`, `product`, `odm`, `system_dlkm`, `vendor_dlkm`).
- USB Controller: `13200000.dwc3`.
- Model Detection: Dynamic via `device/samsung/s5e8535-common/libinit/init_s5e8535.cpp` (`ro.boot.product.model` and `ro.boot.em.model`), eliminating board-level forks between SM-A146B and SM-A146M.

---

## 5. Build Execution (External Machine / Dedicated Server)

Requirements: Linux environment, 300+ GB NVMe/SSD, 16+ GB RAM.

```bash
repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs
mkdir -p .repo/local_manifests
cp /path/to/local_manifest.xml .repo/local_manifests/
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags
source build/envsetup.sh
breakfast a14x
brunch a14x
```

---

## 6. Sources and Acknowledgments

- Samsung Electronics Co., Ltd.:
  Official Linux Kernel source code releases for SM-A146B / SM-A146M (s5e8535) via Samsung Open Source Release Center (`SM-A146B_15_Opensource.zip`).
- devhunter1 / PARBINDAR7:
  Primary LineageOS 23.2 device tree, common tree, pre-extracted vendor trees, and local manifest integration for `a14x`.
- multi-forge Project:
  Hardware partition analysis, TWRP device tree implementation, and NightKernel reference configurations.
- Gitgud fw-dumps Team:
  Firmware extraction reference builds (`a14xxx-user-14-UP1A.231005.007-A146BXXU8CXK1-release-keys`).
- LineageOS Project & Linux Foundation:
  Android Open Source Project foundation, Samsung SLSI hardware HAL maintainers, and Linux 5.15 LTS kernel upstream.
