#!/bin/bash
set -e

# 1. Fetch latest DataGrip release info
RELEASES_URL="https://data.services.jetbrains.com/products/releases?code=DG&latest=true&type=release"
DOWNLOAD_URL=$(curl -s "$RELEASES_URL" | jq -r '.DG[0].downloads.linux.link')
VERSION=$(curl -s "$RELEASES_URL" | jq -r '.DG[0].version')

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" == "null" ]; then
  echo "Error: Could not find download URL for DataGrip."
  exit 1
fi
echo "Download URL: $DOWNLOAD_URL"

# 2. Download and extract
mkdir -p build
cd build
wget -q --show-progress "$DOWNLOAD_URL" -O datagrip.tar.gz
mkdir -p DataGrip.AppDir
tar -xzf datagrip.tar.gz -C DataGrip.AppDir --strip-components=1

# 3. Create AppRun
# JetBrains IDEs need a bit of a wrapper or just execute bin/datagrip.sh
cat <<EOF > DataGrip.AppDir/AppRun
#!/bin/sh
HERE="\$(dirname "\$(readlink -f "\${0}")")"
export DATAGRIP_JDK="\${HERE}/jbr"
exec "\${HERE}/bin/datagrip.sh" "\$@"
EOF
chmod +x DataGrip.AppDir/AppRun

# 4. Create Desktop File
# Usually there is one in bin/ but let's make a clean one
cat <<EOF > DataGrip.AppDir/datagrip.desktop
[Desktop Entry]
Name=DataGrip
Exec=datagrip %u
Terminal=false
Type=Application
Icon=datagrip
Categories=Development;IDE;Database;
Comment=JetBrains DataGrip
StartupWMClass=jetbrains-datagrip
EOF

# 5. Copy Icon
cp DataGrip.AppDir/bin/datagrip.png DataGrip.AppDir/datagrip.png
cp DataGrip.AppDir/bin/datagrip.svg DataGrip.AppDir/datagrip.svg || true

# 6. Download appimagetool
wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
if [ ! -f "appimagetool" ]; then
  echo "Error: Failed to download appimagetool"
  exit 1
fi
chmod +x appimagetool

# 7. Build AppImage
# Disable sandbox and use extract-and-run if FUSE is missing
export ARCH=x86_64
export APPIMAGE_EXTRACT_AND_RUN=1

# Definir información de actualización (GitHub Releases)
# Formato: gh-releases-zsync|<user>|<repo>|latest|<artifact_name>.zsync
# Reemplaza <user> y <repo> con tus datos o déjalos como variables si el script los conoce
# Por ahora usamos un placeholder que el usuario debe ajustar o que podemos intentar detectar
REPO_OWNER=$(echo $GITHUB_REPOSITORY | cut -d'/' -f1)
REPO_NAME=$(echo $GITHUB_REPOSITORY | cut -d'/' -f2)

if [ ! -z "$GITHUB_REPOSITORY" ]; then
  UPDATE_INFO="gh-releases-zsync|${REPO_OWNER}|${REPO_NAME}|latest|DataGrip-x86_64.AppImage.zsync"
  ./appimagetool -u "$UPDATE_INFO" DataGrip.AppDir DataGrip-x86_64.AppImage
else
  ./appimagetool DataGrip.AppDir DataGrip-x86_64.AppImage
fi

echo "Build complete: build/DataGrip-x86_64.AppImage"
