#!/bin/bash

export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-/home/${SUDO_USER:-$USER}/.Xauthority}"
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
export SCRIPT_DIR

if [ ! -f "$SCRIPT_DIR/config.env" ]; then
    echo "Arquivo config.env ausente. Copie config.env.example para config.env e revise os valores." >&2
    exit 1
fi

source "$SCRIPT_DIR/config.env"
for module in "$SCRIPT_DIR/modules"/*.sh; do
    source "$module"
done

ERRORS=()
START_TIME=$(date +%s)

full_deploy() {
    FIFO=$(mktemp -u /tmp/hrsaj_fifo_XXXXXX)
    mkfifo "$FIFO"
    zenity --progress --title="HRSAJ Deploy" --text="Iniciando..." --percentage=0 --auto-close --width=500 < "$FIFO" &
    ZENITY_PID=$!
    exec 3>"$FIFO"

    _progress() { echo "$1" >&3; echo "# $2" >&3; }
    _step() {
        local TITLE="$1" FUNC="$2" PCT="$3"
        _progress "$PCT" "$TITLE"
        local STATE_KEY
        STATE_KEY=$(printf '%s' "$FUNC" | tr '[:upper:]' '[:lower:]')
        if "$FUNC"; then
            state_mark_ok "$STATE_KEY" "$TITLE validado/executado"
            log_ok "$TITLE concluído"
        else
            state_mark_failed "$STATE_KEY" "$TITLE falhou"
            ERRORS+=("$TITLE falhou")
            log_error "$TITLE falhou"
            if ! zenity --question --title="Falha em $TITLE" --text="$TITLE falhou.\nDeseja continuar o deploy?" --width=400 2>/dev/null; then
                exec 3>&-
                rm -f "$FIFO"
                kill "$ZENITY_PID" 2>/dev/null || true
                exit 1
            fi
        fi
    }

    AUDIT_INTERACTIVE=false
    _step "Auditoria" audit_system 5
    AUDIT_INTERACTIVE=true
    _step "Rede" network_check 10
    _step "Usuários" create_users 20
    _step "Chrome" install_chrome 30
    _step "AnyDesk" install_anydesk 40
    _step "Weasis" install_weasis 50
    _step "Wallpaper" set_wallpaper 60
    _step "Atalhos" create_desktop_shortcuts 68
    _step "Impressoras" install_printers 75
    _step "Samba" install_samba 85
    _step "Favoritos" apply_favorites 92
    _step "Relatório" generate_report 97

    _progress 100 "Concluído"
    exec 3>&-
    rm -f "$FIFO"
    wait "$ZENITY_PID" 2>/dev/null || true
    show_summary
}

main_menu
