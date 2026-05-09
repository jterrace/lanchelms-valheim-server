#!/usr/bin/env bash

NAMESPACE="LanChelms"
MOD="DeepNorthModpack"
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CFG="${HOME}/lanchelms-valheim-data/server/BepInEx/config/RustyMods.Seasonality.cfg"

echo "Fetching latest version for ${NAMESPACE}/${MOD}..."
VERSION=$(curl -s "https://thunderstore.io/api/v1/package-metrics/${NAMESPACE}/${MOD}/" | jq -r '.latest_version')
[ -z "${VERSION}" ] || [ "${VERSION}" == "null" ] && { echo "Error: Fetch failed."; exit 1; }

echo "Downloading ${VERSION}..."
mkdir -p "${BASE_DIR}/tmp/"
OUTPUT_FILE="${BASE_DIR}/tmp/${NAMESPACE}_${MOD}_${VERSION}.zip"
wget -q --show-progress -O "${OUTPUT_FILE}" "https://thunderstore.io/package/download/${NAMESPACE}/${MOD}/${VERSION}/" || { echo "Download failed."; exit 1; }

# Prompt to stop the server
read -p "Download complete. Stop the Docker container to apply? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && (cd "${BASE_DIR}" && docker compose stop)

# Backup the config and grab the current season
BAK="${CFG}.$(date +%s).bak"
cp "$CFG" "$BAK"
SEASON=$(grep "^Season =" "$BAK" | cut -d'=' -f2 | xargs)

echo "Installing modpack..."
cd ~/r2modman-headless
go run . --install-dir ~/lanchelms-valheim-data/server/ --profile-zip "${OUTPUT_FILE}"

# Restore the season to the newly extracted config
sed -i "s/^Season =.*/Season = ${SEASON}/" "${CFG}"
echo "Restored season to: ${SEASON}"

# Clean up and move Gizmo
rm -rf ~/lanchelms-valheim-data/server/BepInEx/config/AzuAntiCheat_Greylist/**
mv ~/lanchelms-valheim-data/server/BepInEx/plugins/ComfyMods-Gizmo ~/lanchelms-valheim-data/server/BepInEx/config/AzuAntiCheat_Greylist/

# Prompt to start the server
read -p "Update finished. Start the Docker container? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && (cd "${BASE_DIR}" && docker compose start)
