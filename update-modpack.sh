#!/usr/bin/env bash

NAMESPACE="LanChelms"
MOD="DeepNorthModpack"

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Fetching latest version for ${NAMESPACE}/${MOD}..."
VERSION=$(curl -s "https://thunderstore.io/api/v1/package-metrics/${NAMESPACE}/${MOD}/" | jq -r '.latest_version')
if [ -z "${VERSION}" ] || [ "${VERSION}" == "null" ]; then
  echo "Error: Failed to fetch the latest version."
  exit 1
fi
echo "Latest version found: ${VERSION}"

DOWNLOAD_URL="https://thunderstore.io/package/download/${NAMESPACE}/${MOD}/${VERSION}/"
echo "Downloading from ${DOWNLOAD_URL}..."
mkdir -p "${BASE_DIR}/tmp/"
OUTPUT_FILE="${BASE_DIR}/tmp/${NAMESPACE}_${MOD}_${VERSION}.zip"
if ! wget -q --show-progress -O "${OUTPUT_FILE}" "${DOWNLOAD_URL}"; then
  echo "Error: Download failed."
  exit 1
fi
echo "Success! Saved as ${OUTPUT_FILE}"

cd ~/r2modman-headless
go run . --install-dir ~/lanchelms-valheim-data/server/ --profile-zip "${OUTPUT_FILE}"

rm -rf ~/lanchelms-valheim-data/server/BepInEx/config/AzuAntiCheat_Greylist/**
mv ~/lanchelms-valheim-data/server/BepInEx/plugins/ComfyMods-Gizmo ~/lanchelms-valheim-data/server/BepInEx/config/AzuAntiCheat_Greylist/

