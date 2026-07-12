#!/bin/bash

install_anydesk() {
    if command -v anydesk >/dev/null 2>&1; then
        log_ok "AnyDesk já instalado"
        return 0
    fi

    install -d -m 0755 /etc/apt/keyrings
    if [ ! -f /etc/apt/keyrings/anydesk.gpg ]; then
        wget -qO- https://keys.anydesk.com/repos/DEB-GPG-KEY | gpg --dearmor -o /etc/apt/keyrings/anydesk.gpg
    fi
    echo 'deb [signed-by=/etc/apt/keyrings/anydesk.gpg] http://deb.anydesk.com/ all main' > /etc/apt/sources.list.d/anydesk.list
    apt-get update
    apt-get install -y anydesk && return 0

    if [ -f "$SCRIPT_DIR/assets/anydesk.deb" ]; then
        dpkg -i "$SCRIPT_DIR/assets/anydesk.deb" || apt-get -f install -y
    fi
    command -v anydesk >/dev/null 2>&1
}
