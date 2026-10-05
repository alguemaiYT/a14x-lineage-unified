#!/usr/bin/env bash
# Automated LineageOS 23.2 compilation script for Samsung Galaxy A14 5G (a14x)
# Platform: Exynos 1330 (s5e8535) | Target: SM-A146B / SM-A146M
set -uo pipefail

LOG_FILE="/var/log/a14x_build.log"
GCS_BUCKET="gs://stt-465818-anthor-apks/a14x-builds"

exec > >(tee -a "${LOG_FILE}") 2>&1

cleanup() {
    EXIT_CODE=$?
    echo "=========================================="
    echo "BUILD PROCESS ENDED WITH EXIT CODE: ${EXIT_CODE}"
    echo "Timestamp: $(date -u)"
    echo "=========================================="

    # Upload build log regardless of outcome
    echo "Uploading execution logs to Cloud Storage..."
    gsutil cp "${LOG_FILE}" "${GCS_BUCKET}/a14x_build_$(date +%Y%m%d_%H%M%S).log" || true

    # Upload output artifacts if they exist
    if [ -d "/root/android/lineage/out/target/product/a14x" ]; then
        echo "Uploading compiled images and ROM zip to ${GCS_BUCKET}..."
        gsutil -m cp /root/android/lineage/out/target/product/a14x/lineage-*.zip "${GCS_BUCKET}/" || true
        gsutil cp /root/android/lineage/out/target/product/a14x/boot.img "${GCS_BUCKET}/" || true
        gsutil cp /root/android/lineage/out/target/product/a14x/recovery.img "${GCS_BUCKET}/" || true
        gsutil cp /root/android/lineage/out/target/product/a14x/init_boot.img "${GCS_BUCKET}/" || true
    fi

    echo "CRITICAL: Powering down VM immediately to terminate billing..."
    poweroff
}

trap cleanup EXIT

echo "=== STEP 1: SYSTEM PREPARATION & DEPENDENCIES ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y     bc bison build-essential ccache curl flex g++-multilib gcc-multilib     git git-lfs gnupg gperf imagemagick lib32readline-dev lib32z1-dev     libelf-dev liblz4-tool libncurses5 libncurses5-dev libsdl1.2-dev     libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool     squashfs-tools xsltproc zip zlib1g-dev python3 openjdk-17-jdk libncurses5

# Setup 8 GB swap to prevent OOM during ninja linking
if [ ! -f /swapfile ]; then
    echo "Allocating 8GB swapfile..."
    fallocate -l 8G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=8192
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
fi

# Install repo binary
mkdir -p /usr/local/bin
curl -s https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo
chmod a+x /usr/local/bin/repo

echo "=== STEP 2: GIT & WORKSPACE CONFIGURATION ==="
git config --global user.name "alguemaiYT"
git config --global user.email "alguemaiYT@users.noreply.github.com"
git config --global color.ui false

WORKDIR="/root/android/lineage"
mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

echo "=== STEP 3: REPO INITIALIZATION & MANIFEST SETUP ==="
repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --depth=1 --git-lfs

mkdir -p .repo/local_manifests
git clone -b lineage-23.2 https://github.com/alguemaiYT/local_manifests.git .repo/local_manifests

echo "=== STEP 4: REPO SYNC ==="
repo sync -c -j8 --force-sync --no-clone-bundle --no-tags --optimized-fetch

echo "=== STEP 5: COMPILATION (lineage-23.2 for a14x) ==="
source build/envsetup.sh
breakfast a14x
brunch a14x

echo "=== BUILD COMPLETED SUCCESSFULLY ==="
