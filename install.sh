#!/bin/bash
# =============================================================================
# install.sh — Installation rapide d'ALLA Banc pour le client
#
# Usage (une seule commande à copier-coller dans un terminal) :
#   curl -sL https://raw.githubusercontent.com/dlabel1/alla-banc-release/main/install.sh | bash
#
# Ce script :
#   1. Télécharge bootstrap.sh depuis GitHub
#   2. Crée le raccourci "Installer ALLA Banc" sur le bureau
#   3. Lance l'installation
# =============================================================================

set -euo pipefail

GITHUB_RAW="https://raw.githubusercontent.com/dlabel1/alla-banc-release/main"
BOOTSTRAP_URL="$GITHUB_RAW/bootstrap.sh"
BOOTSTRAP_DST="/usr/local/bin/cim_banc_bootstrap.sh"
DESKTOP_FILE_NAME="Installer ALLA Banc.desktop"
DESKTOP_DIR="$HOME/Desktop"

echo "=== ALLA Banc — Installation ==="
echo ""

# Vérifier la connexion internet
if ! curl -sf --max-time 10 "https://github.com" > /dev/null 2>&1; then
    echo "Erreur : pas de connexion internet."
    echo "Connectez le Pi au réseau (Wi-Fi ou câble) et réessayez."
    exit 1
fi

# Vérifier que le bureau existe
if [ ! -d "$DESKTOP_DIR" ]; then
    echo "Erreur : dossier Desktop introuvable ($DESKTOP_DIR)"
    exit 1
fi

# Télécharger bootstrap.sh
echo "Téléchargement du programme d'installation..."
TMP_BOOTSTRAP=$(mktemp /tmp/bootstrap_XXXXXX.sh)
if ! curl -sfL "$BOOTSTRAP_URL" -o "$TMP_BOOTSTRAP"; then
    rm -f "$TMP_BOOTSTRAP"
    echo "Erreur : impossible de télécharger le programme d'installation."
    exit 1
fi

# Installer bootstrap.sh (nécessite sudo)
echo "Installation... (mot de passe sudo requis)"
sudo cp "$TMP_BOOTSTRAP" "$BOOTSTRAP_DST"
sudo chmod +x "$BOOTSTRAP_DST"
rm -f "$TMP_BOOTSTRAP"
echo "OK : $BOOTSTRAP_DST"

# Créer le raccourci bureau
DESKTOP_FILE="$DESKTOP_DIR/$DESKTOP_FILE_NAME"
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Installer ALLA Banc
Comment=Installe l'application ALLA Banc (connexion internet requise)
Exec=$BOOTSTRAP_DST
Icon=system-software-install
Terminal=false
Type=Application
StartupNotify=false
EOF

chmod +x "$DESKTOP_FILE"

# Marquer comme trusted
if command -v gio &>/dev/null; then
    gio set "$DESKTOP_FILE" metadata::trusted true 2>/dev/null || true
fi

echo "OK : raccourci créé sur le bureau"
echo ""
echo "=== Terminé ==="
echo ""
echo "Double-cliquez sur \"Installer ALLA Banc\" sur le bureau pour lancer l'installation."
echo ""

# Proposer de lancer directement
read -rp "Lancer l'installation maintenant ? [O/n] " answer
if [[ -z "$answer" || "$answer" =~ ^[OoYy]$ ]]; then
    exec bash "$BOOTSTRAP_DST"
fi
