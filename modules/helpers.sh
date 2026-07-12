#!/bin/bash

LOGFILE="/var/log/hrsaj_deploy.log"
STATE_DIR="${HRSAJ_STATE_DIR:-/var/lib/hrsaj-deploy}"
STATE_FILE="$STATE_DIR/state.tsv"
RUN_ID="${RUN_ID:-$(date '+%Y%m%d-%H%M%S')}"

ensure_state_dir() {
    mkdir -p "$STATE_DIR"
    touch "$STATE_FILE"
    chmod 755 "$STATE_DIR"
    chmod 644 "$STATE_FILE"
}

log() {
    mkdir -p "$(dirname "$LOGFILE")"
    local MSG="[$(date '+%F %T')] $1"
    echo "$MSG" | tee -a "$LOGFILE"
}
log_ok() { log "[OK] $1"; }
log_warn() { log "[WARN] $1"; }
log_error() { log "[ERROR] $1"; }

state_get() {
    ensure_state_dir
    awk -F '\t' -v key="$1" '$1==key {value=$2} END {print value}' "$STATE_FILE"
}

state_set() {
    local key="$1" value="$2" detail="${3:-}"
    ensure_state_dir
    local tmp
    tmp=$(mktemp)
    awk -F '\t' -v key="$key" '$1!=key' "$STATE_FILE" > "$tmp"
    printf '%s\t%s\t%s\t%s\t%s\n' "$key" "$value" "$(date --iso-8601=seconds)" "$RUN_ID" "$detail" >> "$tmp"
    mv "$tmp" "$STATE_FILE"
    chmod 644 "$STATE_FILE"
}

state_mark_ok() { state_set "$1" ok "${2:-}"; }
state_mark_failed() { state_set "$1" failed "${2:-}"; }

package_installed() {
    if command -v dpkg-query >/dev/null 2>&1; then
        dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'
    elif command -v rpm >/dev/null 2>&1; then
        rpm -q "$1" >/dev/null 2>&1
    else
        return 1
    fi
}

service_active() {
    systemctl is-active --quiet "$1" 2>/dev/null
}

file_content_equals() {
    [ -f "$1" ] && cmp -s "$1" "$2"
}

safe_install_file() {
    local source="$1" dest="$2" owner="${3:-root:root}" mode="${4:-0644}"
    local dest_dir
    dest_dir=$(dirname "$dest")
    mkdir -p "$dest_dir"
    if [ -f "$dest" ] && cmp -s "$source" "$dest"; then
        chown "$owner" "$dest" 2>/dev/null || true
        chmod "$mode" "$dest" 2>/dev/null || true
        return 2
    fi
    install -o "${owner%%:*}" -g "${owner##*:}" -m "$mode" "$source" "$dest"
}

run_step() {
    local TITLE="$1" FUNCTION="$2"
    if "$FUNCTION"; then
        log_ok "$TITLE concluído"
    else
        log_error "$TITLE falhou"
        if zenity --question --title="Falha" --text="$TITLE falhou. Deseja continuar?" --width=400 2>/dev/null; then
            return 0
        fi
        exit 1
    fi
}

show_summary() {
    local END_TIME ELAPSED SUMMARY
    END_TIME=$(date +%s)
    ELAPSED=$(( END_TIME - START_TIME ))
    SUMMARY="======= HRSAJ DEPLOY =======\n\n"
    if [ ${#ERRORS[@]} -eq 0 ]; then
        SUMMARY+="✔ Todos os módulos executados ou validados com sucesso\n\n"
    else
        SUMMARY+="⚠ Ocorreram falhas:\n\n"
        for err in "${ERRORS[@]}"; do SUMMARY+="  • $err\n"; done
    fi
    SUMMARY+="\nTempo total: ${ELAPSED}s"
    SUMMARY+="\nLog completo: $LOGFILE"
    SUMMARY+="\nEstado persistente: $STATE_FILE"
    zenity --info --title="Resumo do Deploy" --width=560 --height=420 --text="$SUMMARY" 2>/dev/null || true
}
