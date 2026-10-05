# Android device tree for Samsung Galaxy A14 5G (a14x)

```
#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
```

The Samsung Galaxy A14 5G (codenamed `a14x`) is an entry-level smartphone from Samsung.
It was announced in January 2023.

## Device Specifications

| Feature | Specification |
| :--- | :--- |
| SoC | Samsung Exynos 1330 (s5e8535) |
| CPU | Octa-core (2x2.4 GHz Cortex-A78 & 6x2.0 GHz Cortex-A55) |
| GPU | ARM Mali-G68 MP2 |
| Board | SRPVG28A003 / erd8535 |
| Memory | 4 GB / 6 GB / 8 GB LPDDR4X |
| Storage | 64 GB / 128 GB UFS 2.2 |
| Battery | 5000 mAh Li-Po (15W charging) |
| Display | 1080 x 2408 pixels, 20:9 ratio, 90Hz PLS LCD, 6.6 inches |
| Shipped OS | Android 13 with One UI Core 5.0 |

## Supported Models

* SM-A146B (Global)
* SM-A146M (Latin America)
* SM-M146B (Galaxy M14 5G)

All models share the `s5e8535` platform and are dynamically resolved at first stage init via `libinit_s5e8535`.

## To build LineageOS 23.2:

```bash
# 1. Initialize LineageOS source repository
repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs

# 2. Clone personal local manifest
git clone -b lineage-23.2 https://github.com/alguemaiYT/local_manifests.git .repo/local_manifests

# 3. Synchronize all repositories
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags

# 4. Setup build environment and compile
. build/envsetup.sh
breakfast a14x
brunch a14x
```

## GitHub Codespaces Application and Lifecycle

This tree can be reviewed, edited, and maintained within GitHub Codespaces.

* Direct Launch URL: https://github.com/codespaces/new/alguemaiYT/a14x-lineage-unified
* Quota Rule: Always shut down your instance immediately after completing commits to preserve core-hour limits:
```bash
sudo shutdown -h now
# Or from external terminal:
gh codespace stop -r alguemaiYT/a14x-lineage-unified
```
* Storage Boundary: Compiling LineageOS requires 300+ GB of disk space. Perform builds on dedicated hardware, not inside standard Codespaces containers.

## Device Picture

![Samsung Galaxy A14 5G](https://fdn2.gsmarena.com/vv/pics/samsung/samsung-galaxy-a14-5g-1.jpg)

## Sources and Credits

* Samsung Electronics Co., Ltd. (Base kernel sources via Open Source Release Center)
* devhunter1 / PARBINDAR7 (Original LineageOS 23.2 trees and manifest setup)
* multi-forge Project (Partition forensics, TWRP baseline, NightKernel)
* Gitgud fw-dumps Team (Reference partition dumps)
* LineageOS Project & Upstream Linux Maintainers
