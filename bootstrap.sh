#!/bin/bash
export DISPLAY="${DISPLAY:-:0}"

LATEST_JSON_URL="https://raw.githubusercontent.com/dlabel1/alla-banc-release/main/latest.json"

DONE_STEPS=""
CURRENT_STEP=""

step() {
    if [ -n "$CURRENT_STEP" ]; then
        if [ -n "$DONE_STEPS" ]; then
            DONE_STEPS="${DONE_STEPS}\n${CURRENT_STEP}  OK"
        else
            DONE_STEPS="${CURRENT_STEP}  OK"
        fi
    fi
    CURRENT_STEP="$1"
    if [ -n "$DONE_STEPS" ]; then
        echo "# ${DONE_STEPS}\n${CURRENT_STEP}" >&3
    else
        echo "# ${CURRENT_STEP}" >&3
    fi
}

error_exit() {
    kill "$ZENITY_PID" 2>/dev/null
    exec 3>&- 2>/dev/null
    rm -f "$PIPE" "$TMP_JSON" 2>/dev/null
    zenity --error --title="Erreur d'installation" --text="$1" --width=400 2>/dev/null
    exit 1
}

ZENITY_PID=""
PIPE=""
TMP_JSON=""
TMP_TAR=""

zenity --question \
    --title="ALLA Banc — Installation" \
    --text="Bienvenue !\n\nL'application ALLA Banc va être téléchargée et installée automatiquement.\n\nAssurez-vous que le Raspberry Pi est connecté à internet.\n\nCommencer l'installation ?" \
    --ok-label="Installer" \
    --cancel-label="Annuler" \
    --width=400 2>/dev/null || exit 0

if ! curl -sf --max-time 10 "https://github.com" > /dev/null 2>&1; then
    zenity --error \
        --title="Pas de connexion internet" \
        --text="Impossible de contacter le serveur.\n\nConnectez le Raspberry Pi au réseau et réessayez." \
        --width=400 2>/dev/null
    exit 1
fi

PIPE=$(mktemp -u /tmp/cim_bootstrap_pipe_XXXXXX)
mkfifo "$PIPE"
zenity --progress \
    --title="ALLA Banc — Installation" \
    --text="Connexion au serveur..." \
    --pulsate \
    --no-cancel \
    --width=400 < "$PIPE" &
ZENITY_PID=$!
exec 3>"$PIPE"

step "Connexion au serveur..."

TMP_JSON=$(mktemp /tmp/cim_latest_XXXXXX.json)
if ! curl -sf --max-time 30 "$LATEST_JSON_URL" -o "$TMP_JSON" 2>/dev/null; then
    error_exit "Impossible de récupérer les informations de la dernière version.\n\nVérifiez votre connexion internet."
fi

VERSION=$(python3 -c "import json,sys; d=json.load(open('$TMP_JSON')); print(d['version'])" 2>/dev/null)
TAR_URL=$(python3  -c "import json,sys; d=json.load(open('$TMP_JSON')); print(d['url'])"     2>/dev/null)
SHA256=$(python3   -c "import json,sys; d=json.load(open('$TMP_JSON')); print(d['sha256'])"  2>/dev/null)

[[ -z "$VERSION" || -z "$TAR_URL" ]] && error_exit "Réponse serveur invalide. Réessayez plus tard."

step "Téléchargement v${VERSION}..."

TMP_TAR="/tmp/CIM_Banc_${VERSION}.tar.gz"
if ! curl -L --max-time 300 "$TAR_URL" -o "$TMP_TAR" 2>/dev/null; then
    error_exit "Échec du téléchargement.\n\nVérifiez votre connexion internet et réessayez."
fi

step "Vérification de l'intégrité..."

ACTUAL_SHA=$(sha256sum "$TMP_TAR" | cut -d' ' -f1)
if [[ "$ACTUAL_SHA" != "$SHA256" ]]; then
    rm -f "$TMP_TAR"
    error_exit "Le fichier téléchargé est corrompu.\n\nRelancez l'installation."
fi

step "Préparation de l'installation..."

if ! tar xzf "$TMP_TAR" -C /tmp CIM_Banc/reset_pi5.sh --strip-components=1 2>/dev/null; then
    error_exit "Impossible d'extraire le programme d'installation depuis l'archive."
fi
chmod +x /tmp/reset_pi5.sh

step "Installation en cours..."

if ! sudo bash /tmp/reset_pi5.sh "$TMP_TAR" --yes 2>/tmp/cim_install_error.log; then
    INSTALL_LOG=$(tail -5 /tmp/cim_install_error.log 2>/dev/null)
    error_exit "L'installation a échoué.\n\n$INSTALL_LOG"
fi

kill "$ZENITY_PID" 2>/dev/null
exec 3>&-
rm -f "$PIPE" "$TMP_JSON" /tmp/reset_pi5.sh /tmp/cim_install_error.log

zenity --info \
    --title="Installation réussie !" \
    --text="ALLA Banc v$VERSION a été installé avec succès.\n\nDouble-cliquez sur l'icône ALLA Banc sur le bureau pour lancer l'application." \
    --width=400 2>/dev/null
