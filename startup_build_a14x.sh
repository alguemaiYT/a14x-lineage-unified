#!/usr/bin/env bash
# Automated LineageOS 23.2 compilation script for Samsung Galaxy A14 5G (a14x)
# Platform: Exynos 1330 (s5e8535) | Target: SM-A146B / SM-A146M
set -eo pipefail

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

export HOME="/root"
export USER="root"
export ANDROID_BUILD_TOP="/root/android/lineage"

WORKDIR="/root/android/lineage"
cd "${WORKDIR}"

echo "=== VERIFYING REPO WORKSPACE INTEGRITY ==="
ls -la "${WORKDIR}/build/envsetup.sh"
ls -d "${WORKDIR}/device/samsung/a14x"
ls -d "${WORKDIR}/vendor/samsung/a14x"
ls -d "${WORKDIR}/kernel/samsung/s5e8535"

echo "=== STEP 5: COMPILATION (lineage-23.2 for a14x) ==="
# Disable nounset specifically for AOSP scripts
set +u

source build/envsetup.sh
breakfast a14x
brunch a14x

echo "=== BUILD COMPLETED SUCCESSFULLY ==="
