@echo off
echo =======================================================
echo Launching automated LineageOS 23.2 build VM for a14x
echo Project: stt-465818 ^| Zone: us-east1-b ^| Machine: e2-standard-8 Spot
echo =======================================================

cmd.exe /c gcloud compute instances create a14x-spot-build ^
    --project=stt-465818 ^
    --zone=us-east1-b ^
    --machine-type=e2-standard-8 ^
    --provisioning-model=SPOT ^
    --boot-disk-size=240GB ^
    --boot-disk-type=pd-balanced ^
    --image-family=ubuntu-2204-lts ^
    --image-project=ubuntu-os-cloud ^
    --scopes=cloud-platform ^
    --metadata-from-file=startup-script=startup_build_a14x.sh

echo =======================================================
echo VM deployed. Build is executing in background.
echo To tail live output:
echo   cmd.exe /c gcloud compute instances get-serial-port-output a14x-spot-build --project=stt-465818 --zone=us-east1-b --port=1
echo Artifacts and logs will be uploaded to:
echo   gs://stt-465818-anthor-apks/a14x-builds/
echo The VM will power down automatically when complete.
echo =======================================================
pause
