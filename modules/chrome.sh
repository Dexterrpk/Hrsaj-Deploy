#!/bin/bash

install_chrome() {
    if command -v google-chrome &>/dev/null || command -v google-chrome-stable &>/dev/null; then
        log_ok "Chrome já instalado; perfil, sessões e favoritos preservados"
        return 0
    fi

    log "Instalando Google Chrome via repositório oficial"
    install -d -m 0755 /etc/apt/keyrings

    if [ ! -f /etc/apt/keyrings/google-chrome.gpg ]; then
        wget -qO- https://dl.google.com/linux/linux_signing_key.pub | \
            gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg
    fi

    cat > /etc/apt/sources.list.d/google-chrome.list <<'REPO'
deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main
REPO

    apt-get update
    if apt-get install -y google-chrome-stable; then
        log_ok "Chrome instalado; nenhum perfil de usuário foi alterado"
        return 0
    fi

    if [ -f "$SCRIPT_DIR/assets/chrome.deb" ]; then
        dpkg -i "$SCRIPT_DIR/assets/chrome.deb" || apt-get -f install -y
    fi

    command -v google-chrome &>/dev/null || command -v google-chrome-stable &>/dev/null
}
