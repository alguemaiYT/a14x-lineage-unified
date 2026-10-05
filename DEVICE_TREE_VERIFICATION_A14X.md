# SYNTHESIS AND VERIFICATION OF UNIFIED DEVICE TREE — SAMSUNG GALAXY A14 5G (`a14x`)

**Audit Date:** 2026-10-04  
**Certified Targets:** Samsung Galaxy A14 5G (`SM-A146B`, `SM-A146M`) and Galaxy M14 5G (`SM-M146B`)  
**Platform / SoC:** Samsung Exynos 1330 (`s5e8535`), Board `SRPVG28A003` / `erd8535`  
**Base LineageOS Branch:** `lineage-23.2` (Android 15)  
**Local Workspace:** `a14x_lineage_unified`

---

## 1. Unified Device Tree Architecture

The tree structure follows standard AOSP and LineageOS modular designs for Samsung Exynos platforms:

```
a14x_lineage_unified/
├── .devcontainer/
│   └── devcontainer.json               <- GitHub Codespaces container setup
├── .repo/
│   └── local_manifests/
│       └── local_manifest.xml          <- 17 synchronized repositories (lineage-23.2 branch)
├── device/
│   └── samsung/
│       ├── a14x/                       <- Model-specific tree (a14x)
│       │   ├── AndroidProducts.mk
│       │   ├── BoardConfig.mk
│       │   ├── device.mk
│       │   ├── lineage_a14x.mk
│       │   ├── modules.load            <- 295 kernel modules for modular Exynos stack
│       │   ├── vendor.prop
│       │   ├── configs/audio/mixer_paths.xml
│       │   └── overlay/                <- Battery power profiles and hardware overlays
│       └── s5e8535-common/             <- Common SoC platform tree (Exynos 1330)
│           ├── BoardConfigCommon.mk    <- Global hardware flags, partitions, AVB parameters
│           ├── common.mk               <- Hardware abstraction layers, packages, permissions
│           ├── configs/
│           │   ├── init/fstab.s5e8535  <- Hybrid fstab (erofs + ext4, encrypted f2fs data)
│           │   ├── media/              <- Codec2, media profiles, codec XML declarations
│           │   └── audio/              <- Audio policy configuration and volume tables
│           ├── libinit/                <- Dynamic bootloader model unification
│           ├── libshims/               <- libdsms, libepicoperator, libhypervintf, libsensorsndkbridge
│           ├── sepolicy/               <- Full vendor SELinux policy rules
│           └── vintf/                  <- Compatibility matrices and device manifest
├── FORK_GUIDE.md                       <- Step-by-step fork and Codespaces manual
├── DEVICE_TREE_VERIFICATION_A14X.md    <- Technical verification audit log
├── fork_repos.sh                       <- Automation script for batch repository forks
└── README.md                           <- Repository documentation and build guide
```

---

## 2. Hardware Parameters and Partition Offsets

All parameters match raw GPT tables and hardware forensics down to the byte:

| Parameter | Verified Value | Technical Notes |
| :--- | :--- | :--- |
| **Boot Image** | `67,108,864` bytes (64 MB) | **Header v4**, empty ramdisk, loads `Image` and `bootconfig` |
| **Init Boot Image** | `16,777,216` bytes (16 MB) | **Header v4**, contains first-stage system ramdisk |
| **Recovery Image** | `100,663,296` bytes (96 MB) | **Header v2**, zero DTB offset, embedded `recovery_dtbo` |
| **Super Partition** | `8,287,944,704` bytes (~7.72 GiB) | Physical super container |
| **Dynamic Group** | `8,283,750,400` bytes | `system`, `system_ext`, `vendor`, `product`, `odm`, `dlkm` |
| **DTBO Partition** | `8,388,608` bytes (8 MB) | Compiled separately (`BOARD_KERNEL_SEPARATED_DTBO := true`) |
| **USB Controller** | `13200000.dwc3` | DWC3 gadget defined in Soong configuration |
| **Kernel Page Size** | `4096` bytes (4 KB) | Offsets: Base `0x10000000`, Kernel `0x00008000`, DTB `0x01f00000` |

---

## 3. Dynamic Model Unification (SM-A146B vs SM-A146M)

Separate builds for SM-A146B and SM-A146M are unnecessary. Unification is executed at first-stage init by `libinit_s5e8535` (`device/samsung/s5e8535-common/libinit/init_s5e8535.cpp`):

```cpp
model = GetProperty("ro.boot.product.model", "");
if (model.empty()) {
    model = GetProperty("ro.boot.em.model", "");
}
set_ro_build_prop("model", model);
```

The bootloader transmits the hardware SKU via kernel cmdline (`ro.boot.product.model` or `ro.boot.em.model`). `vendor_init` reads this parameter and populates all Android namespaces (`ro.product.model`, `ro.product.system.model`, `ro.product.vendor.model`), ensuring safety checks, Google Play Services, and carrier configuration work without maintaining redundant device trees.

---

## 4. Local Manifest Source Map (`lineage-23.2`)

The local manifest `.repo/local_manifests/local_manifest.xml` manages the 17 component repositories:

- **Device Trees:** `alguemaiYT/android_device_samsung_a14x` and `alguemaiYT/android_device_samsung_s5e8535-common`
- **Vendor Trees:** `alguemaiYT/android_vendor_samsung_a14x` and `alguemaiYT/android_vendor_samsung_s5e8535-common`
- **Kernel Source:** `alguemaiYT/android_kernel_samsung_s5e8535` (Linux 5.15.211 LTS with `a14x_defconfig`)
- **SLSI-Linaro Hardware HALs:** Graphics, Config, Exynos, and Sepolicy
- **LineageOS Hardware Modules:** `hardware/samsung`, `libbt`, `wifi_hal`, `wpa_supplicant_lib`, `openmax`, `exynos5`, `interfaces`, `codec2`

---

## 5. Verification Checklist

The test suite executed against the workspace validated 16 out of 16 requirements:

1. `local_manifest.xml` is valid XML with 17 linked projects.
2. `AndroidProducts.mk` targets `lineage_a14x.mk`.
3. `BoardConfig.mk` inherits `BoardConfigCommon.mk`.
4. Boot image header version is set to 4.
5. Boot image size equals 67,108,864 bytes.
6. Init boot image header version is set to 4.
7. Init boot image size equals 16,777,216 bytes.
8. Recovery image size equals 100,663,296 bytes with header v2.
9. Super partition size equals 8,287,944,704 bytes.
10. USB gadget controller targets `13200000.dwc3`.
11. `libinit` handles both `SM-A146B` and `SM-A146M` via `ro.boot.*` properties.
12. `modules.load` contains all 295 required kernel modules.
13. `libdsms` vendor shim is present.
14. `libepicoperator` vendor shim is present.
15. `libhypervintf` vendor shim is present.
16. `libsensorsndkbridge` vendor shim is present.

PASS RATE: 100% (16/16).
