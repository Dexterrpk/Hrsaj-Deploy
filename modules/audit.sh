#!/bin/bash

_audit_row() {
    printf '%-10s | %-24s | %s\n' "$1" "$2" "$3" >> "$REPORT"
}

_count_remote_queues() {
    lpstat -v 2>/dev/null | grep -Eic 'dnssd://|ipp://|ipps://|smb://|lpd://|socket://|implicitclass://'
}

audit_system() {
    ensure_state_dir
    REPORT=$(mktemp /tmp/hrsaj-audit-XXXXXX.txt)
    {
        echo "AUDITORIA HRSAJ - $(date '+%F %T')"
        echo "=============================================================="
    } > "$REPORT"

    service_active cups && _audit_row OK CUPS "serviço ativo" || _audit_row ATENÇÃO CUPS "serviço inativo"
    if systemctl is-active --quiet cups-browsed 2>/dev/null; then
        _audit_row ATENÇÃO "Descoberta remota" "cups-browsed ativo"
    else
        _audit_row OK "Descoberta remota" "desativada"
    fi

    local remote_count
    remote_count=$(_count_remote_queues)
    [ "$remote_count" -eq 0 ] && _audit_row OK "Filas de rede" "nenhuma detectada" || _audit_row ATENÇÃO "Filas de rede" "$remote_count fila(s); revisão manual"

    id "$ADMIN_USER" >/dev/null 2>&1 && _audit_row OK "Usuário admin" "$ADMIN_USER existe" || _audit_row ATENÇÃO "Usuário admin" "$ADMIN_USER ausente"
    id "$DEFAULT_USER" >/dev/null 2>&1 && _audit_row OK "Usuário padrão" "$DEFAULT_USER existe" || _audit_row ATENÇÃO "Usuário padrão" "$DEFAULT_USER ausente"

    command -v google-chrome >/dev/null 2>&1 && _audit_row OK Chrome "instalado; perfil protegido" || _audit_row ATENÇÃO Chrome "não instalado"
    command -v weasis >/dev/null 2>&1 && _audit_row OK Weasis "instalado; configuração protegida" || _audit_row ATENÇÃO Weasis "não instalado"

    {
        echo
        echo "HISTÓRICO DOS MÓDULOS"
        echo "=============================================================="
        [ -s "$STATE_FILE" ] && cat "$STATE_FILE" || echo "Nenhuma execução anterior registrada."
        echo
        echo "Esta auditoria não altera favoritos do Chrome nem configurações do Weasis."
    } >> "$REPORT"

    cp "$REPORT" "$STATE_DIR/last-audit.txt"
    chmod 0644 "$STATE_DIR/last-audit.txt"
    cat "$REPORT"
    if [ "${AUDIT_INTERACTIVE:-true}" = true ]; then
        zenity --text-info --title="Auditoria HRSAJ" --filename="$REPORT" --width=900 --height=620 2>/dev/null || true
    fi
    state_mark_ok audit "auditoria concluída"
}
