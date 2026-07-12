#!/bin/bash
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR" "$SCRIPT_DIR/assets" "$SCRIPT_DIR/reports"
LOG_FILE="$LOG_DIR/bootstrap.log"

log() { local msg="[$(date '+%F %T')] $1"; echo "$msg" | tee -a "$LOG_FILE"; }

if [ ! -f "$SCRIPT_DIR/config.env" ]; then
    cp "$SCRIPT_DIR/config.env.example" "$SCRIPT_DIR/config.env"
    echo "Foi criado $SCRIPT_DIR/config.env. Revise as senhas e execute novamente." >&2
    exit 2
fi

if ! sudo -v; then
    zenity --error --title="Erro" --text="Permissão sudo negada." 2>/dev/null || true
    exit 1
fi

chmod +x "$SCRIPT_DIR/hrsaj_deploy.sh" "$SCRIPT_DIR/install.sh" 2>/dev/null || true
find "$SCRIPT_DIR/modules" -maxdepth 1 -type f -name '*.sh' -exec chmod 0755 {} +

log "Perfis do Chrome e configurações do Weasis serão preservados"

if [ -f /etc/apt/sources.list ]; then
    sudo sed -i '/cdrom:/s/^/#/' /etc/apt/sources.list
fi

sudo apt-get update 2>&1 | tee -a "$LOG_FILE"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    zenity curl wget gnupg net-tools netcat-openbsd cups cups-client cups-filters \
    printer-driver-all system-config-printer hplip samba smbclient cifs-utils \
    python3 python3-pip xdg-user-dirs 2>&1 | tee -a "$LOG_FILE"

sudo systemctl enable --now cups 2>/dev/null || true
sudo -E DISPLAY="${DISPLAY:-:0}" XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}" \
    bash "$SCRIPT_DIR/hrsaj_deploy.sh" 2>&1 | tee -a "$LOG_FILE"
exit ${PIPESTATUS[0]}
