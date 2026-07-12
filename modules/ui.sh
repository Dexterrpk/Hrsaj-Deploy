#!/bin/bash

main_menu() {
    local hostname_input option
    hostname_input=$(zenity --entry --title="HRSAJ Deploy" --text="Nome da máquina (deixe vazio para manter):" 2>/dev/null || true)
    if [ -n "$hostname_input" ] && [ "$hostname_input" != "$(hostname)" ]; then
        hostnamectl set-hostname "$hostname_input" && log_ok "Hostname alterado para $hostname_input"
    fi

    option=$(zenity --list --title="HRSAJ Deploy" --column="Modo" \
        "Deploy Completo" "Auditoria" 2>/dev/null || true)
    case "$option" in
        "Deploy Completo") full_deploy ;;
        "Auditoria") audit_system ;;
        *) log_warn "Operação cancelada" ;;
    esac
}
