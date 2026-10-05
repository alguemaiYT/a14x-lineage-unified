# SÍNTESE E VERIFICAÇÃO DA DEVICE TREE UNIFICADA — SAMSUNG GALAXY A14 5G (`a14x`)

**Data da Auditoria:** 04/10/2026  
**Alvos Homologados:** Samsung Galaxy A14 5G (`SM-A146B`, `SM-A146M`) e Galaxy M14 5G (`SM-M146B`)  
**Plataforma / SoC:** Samsung Exynos 1330 (`s5e8535`), Board `SRPVG28A003` / `erd8535`  
**Base LineageOS:** Branch `lineage-23.2` (Android 15)  
**Diretório Local:** `C:\Users\Aluno\a14x_lineage_unified`

---

## 1. Arquitetura da Device Tree Unificada

A estrutura foi unificada e organizada seguindo os padrões oficiais AOSP/LineageOS para plataformas Exynos:

```
a14x_lineage_unified/
├── .repo/
│   └── local_manifests/
│       └── local_manifest.xml               <- 17 repositórios sincronizados (branch lineage-23.2)
├── device/
│   └── samsung/
│       ├── a14x/                            <- Árvore específica do modelo (a14x)
│       │   ├── AndroidProducts.mk
│       │   ├── BoardConfig.mk
│       │   ├── device.mk
│       │   ├── lineage_a14x.mk
│       │   ├── modules.load                 <- 295 módulos do kernel modular Exynos
│       │   ├── vendor.prop
│       │   ├── configs/audio/mixer_paths.xml
│       │   └── overlay/                     <- Perfis de bateria e ajustes específicos
│       └── s5e8535-common/                  <- Árvore comum da plataforma Exynos 1330
│           ├── BoardConfigCommon.mk         <- Flags globais de hardware, partições e AVB
│           ├── common.mk                    <- Inclusão de HALs, pacotes e permissões
│           ├── configs/
│           │   ├── init/fstab.s5e8535       <- Fstab híbrido (erofs + ext4, f2fs criptografado)
│           │   ├── media/                   <- Codec2, profiles e codecs XML
│           │   └── audio/                   <- Audio policy, volumes e roteamentos
│           ├── libinit/                     <- Detecção dinâmica de SM-A146B / SM-A146M
│           ├── libshims/                    <- libdsms, libepicoperator, libhypervintf, libsensorsndkbridge
│           ├── sepolicy/                    <- Regras SELinux completas de vendor
│           └── vintf/                       <- Compatibility matrix e device manifest
```

---

## 2. Parâmetros Críticos de Hardware e Particionamento

Todos os valores foram verificados e conferidos **ao byte** contra o relatório forense de hardware (`RELATORIO_FORENSE_EXYNOS1330_KERNEL.md`) e os registros das tabelas GPT do aparelho:

| Parâmetro | Valor Verificado | Observações Técnicas |
| :--- | :--- | :--- |
| **Boot Image** | `67,108,864` bytes (64 MB) | **Header v4**, ramdisk vazio, carrega `Image` e `bootconfig` |
| **Init Boot Image** | `16,777,216` bytes (16 MB) | **Header v4**, contém o `system ramdisk` de first-stage init |
| **Recovery Image** | `100,663,296` bytes (96 MB) | **Header v2**, DTB offset zerado, com `recovery_dtbo` embutido |
| **Super Partition** | `8,287,944,704` bytes (~7.72 GiB) | Contém o grupo dinâmico `samsung_dynamic_partitions` |
| **Grupo Dinâmico** | `8,283,750,400` bytes | Partições: `system`, `system_ext`, `vendor`, `product`, `odm`, `system_dlkm`, `vendor_dlkm` |
| **DTBO Partition** | `8,388,608` bytes (8 MB) | DTBO compilado separado (`BOARD_KERNEL_SEPARATED_DTBO := true`) |
| **Controlador USB** | `13200000.dwc3` | DWC3 Gadget configurado no Soong |
| **Page Size do Kernel**| `4096` (4 KB) | Offset: Base `0x10000000`, Kernel `0x00008000`, DTB `0x01f00000` |

---

## 3. Unificação de Modelos: SM-A146B vs SM-A146M

Não é necessário criar árvores separadas para o A146B e A146M. A unificação ocorre dinamicamente na inicialização através da biblioteca **`libinit_s5e8535`** (`device/samsung/s5e8535-common/libinit/init_s5e8535.cpp`):

1. O bootloader informa a variante real do aparelho via linha de comando (`ro.boot.product.model` ou `ro.boot.em.model`).
2. O `vendor_init` intercepta essa propriedade durante o first-stage:
   ```cpp
   model = GetProperty("ro.boot.product.model", "");
   if(model.empty()){
       model = GetProperty("ro.boot.em.model", "");
   }
   set_ro_build_prop("model", model);
   ```
3. O sistema aplica o nome correto (`SM-A146B` ou `SM-A146M`) em todas as namespaces do Android (`ro.product.model`, `ro.product.system.model`, `ro.product.vendor.model`, etc.).
4. Isso garante integridade para Google Play Services, certificações e operadoras sem alterar um único byte na imagem compilada.

---

## 4. O Manifesto Completo (Branch `lineage-23.2`)

O arquivo `.repo/local_manifests/local_manifest.xml` integra as 17 fontes necessárias:

* **Árvores de Dispositivo e Vendor:**
  * `devhunter1/android_device_samsung_a14x`
  * `devhunter1/android_device_samsung_s5e8535-common`
  * `devhunter1/android_vendor_samsung_a14x` (Blobs já extraídos)
  * `devhunter1/android_vendor_samsung_s5e8535-common` (Blobs comuns já extraídos)
* **Kernel:**
  * `devhunter1/android_kernel_samsung_s5e8535` (Linux 5.15.211 LTS com defconfig `a14x_defconfig`)
* **Hardware SLSI-Linaro (SoC Exynos):**
  * `devhunter1/android_hardware_samsung_slsi-linaro_graphics`
  * `devhunter1/android_hardware_samsung_slsi-linaro_config`
  * `devhunter1/android_hardware_samsung_slsi-linaro_exynos`
  * `devhunter1/android_device_samsung_slsi_sepolicy`
* **Stack Hardware LineageOS:**
  * `hardware/samsung`, `hardware/samsung_slsi/libbt`, `wifi_hal`, `wpa_supplicant_lib`, `openmax`, `exynos5`, `interfaces`, `codec2`.

---

## 5. Procedimento de Compilação

Para compilar em ambiente adequado (Linux com 300+ GB de armazenamento e 16+ GB RAM):

```bash
# 1. Inicializar repositório base LineageOS
repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs

# 2. Copiar o local_manifest.xml para .repo/local_manifests/
mkdir -p .repo/local_manifests
cp /caminho/para/local_manifest.xml .repo/local_manifests/

# 3. Sincronizar todos os 17 repositórios
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags

# 4. Configurar ambiente e iniciar a compilação
source build/envsetup.sh
breakfast a14x
brunch a14x
```
