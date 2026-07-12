#!/bin/bash

network_check() {
    systemctl enable --now NetworkManager >/dev/null 2>&1 || true
    ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 && log_ok "Internet acessível" || log_warn "Sem resposta externa"
    getent hosts google.com >/dev/null 2>&1 && log_ok "DNS funcional" || log_warn "Falha de DNS"
    local gateway
    gateway=$(ip route | awk '/default/ {print $3; exit}')
    log "Gateway: ${gateway:-não detectado}"
    nc -z -w2 "$WEASIS_HOST" "$WEASIS_PORT" >/dev/null 2>&1 && log_ok "PACS acessível" || log_warn "PACS inacessível"
    nc -z -w2 "$PRINTSPY_IP" "$PRINTSPY_PORT" >/dev/null 2>&1 && log_ok "PrintSpy acessível" || log_warn "PrintSpy inacessível"
    state_mark_ok network "validação concluída"
}
