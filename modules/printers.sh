#!/bin/bash

_is_local_printer_uri() {
    case "$1" in
        usb://*|parallel:/*|serial:/*|hp:/usb/*|hpfax:/usb/*) return 0 ;;
        *) return 1 ;;
    esac
}

_printer_name_from_uri() {
    local uri="$1" base
    base=$(printf '%s' "$uri" | sed -E 's#^[a-zA-Z0-9+.-]+:(//)?##; s#[?&/=:]+#_#g; s#[^A-Za-z0-9_.-]+#_#g; s#^_+|_+$##g' | cut -c1-48)
    [ -n "$base" ] || base="Local_Printer"
    printf 'HRSAJ_%s\n' "$base"
}

install_printers() {
    systemctl enable --now cups >/dev/null 2>&1 || return 1

    if [ "${DISABLE_REMOTE_PRINTER_DISCOVERY:-true}" = true ]; then
        systemctl disable --now cups-browsed.service >/dev/null 2>&1 || true
        if [ -f /etc/cups/cups-browsed.conf ]; then
            if grep -qE '^[[:space:]]*CreateRemoteCUPSPrinterQueues' /etc/cups/cups-browsed.conf; then
                sed -i 's/^[[:space:]]*CreateRemoteCUPSPrinterQueues.*/CreateRemoteCUPSPrinterQueues No/' /etc/cups/cups-browsed.conf
            else
                printf '\nCreateRemoteCUPSPrinterQueues No\n' >> /etc/cups/cups-browsed.conf
            fi
        fi
    fi

    local uri name existing added=0 skipped=0
    while IFS= read -r uri; do
        [ -n "$uri" ] || continue
        if ! _is_local_printer_uri "$uri"; then skipped=$((skipped+1)); continue; fi
        name=$(_printer_name_from_uri "$uri")
        existing=$(lpstat -v "$name" 2>/dev/null | sed -n 's/.*device for [^:]*: //p')
        if [ "$existing" = "$uri" ]; then
            log_ok "Impressora já configurada: $name"
            continue
        fi
        if lpadmin -p "$name" -E -v "$uri" -m everywhere 2>/dev/null || lpadmin -p "$name" -E -v "$uri" -m raw 2>/dev/null; then
            added=$((added+1))
        else
            log_error "Falha ao configurar $uri"
            return 1
        fi
    done < <(lpinfo -v 2>/dev/null | awk '{print $2}' | sort -u)

    state_mark_ok printers "locais_configuradas=$added remotas_ignoradas=$skipped"
}
