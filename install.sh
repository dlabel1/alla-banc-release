#!/bin/bash
set -euo pipefail

GITHUB_RAW="https://raw.githubusercontent.com/dlabel1/alla-banc-release/main"
BOOTSTRAP_URL="$GITHUB_RAW/bootstrap.sh"
BOOTSTRAP_DST="/usr/local/bin/cim_banc_bootstrap.sh"
DESKTOP_DIR="$HOME/Desktop"

echo "=== ALLA Banc — Installation ==="

if ! curl -sf --max-time 10 "https://github.com" > /dev/null 2>&1; then
    echo "Erreur : pas de connexion internet."
    exit 1
fi

[ ! -d "$DESKTOP_DIR" ] && echo "Erreur : dossier Desktop introuvable" && exit 1

echo "Téléchargement..."
TMP_BOOTSTRAP=$(mktemp /tmp/bootstrap_XXXXXX.sh)
if ! curl -sfL "$BOOTSTRAP_URL" -o "$TMP_BOOTSTRAP"; then
    rm -f "$TMP_BOOTSTRAP"
    echo "Erreur : échec du téléchargement."
    exit 1
fi

sudo cp "$TMP_BOOTSTRAP" "$BOOTSTRAP_DST"
sudo chmod +x "$BOOTSTRAP_DST"
rm -f "$TMP_BOOTSTRAP"

DESKTOP_FILE="$DESKTOP_DIR/Installer ALLA Banc.desktop"
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Installer ALLA Banc
Exec=$BOOTSTRAP_DST
Icon=system-software-install
Terminal=false
Type=Application
StartupNotify=false
EOF

chmod +x "$DESKTOP_FILE"
command -v gio &>/dev/null && gio set "$DESKTOP_FILE" metadata::trusted true 2>/dev/null || true

echo "OK"
echo ""

read -rp "Lancer l'installation maintenant ? [O/n] " answer
if [[ -z "$answer" || "$answer" =~ ^[OoYy]$ ]]; then
    exec bash "$BOOTSTRAP_DST"
fi
