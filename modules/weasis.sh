#!/bin/bash

install_weasis() {
    # Regra HRSAJ: instalação existente e toda a pasta ~/.weasis são intocáveis.
    if command -v weasis &>/dev/null || dpkg-query -W -f='${Status}' weasis 2>/dev/null | grep -q 'install ok installed'; then
        log_ok "Weasis já instalado; versão e configurações preservadas"
        return 0
    fi

    log "Weasis ausente; instalando sem criar ou alterar configurações de usuário"

    if [ -f "$SCRIPT_DIR/assets/weasis.deb" ]; then
        if dpkg -i "$SCRIPT_DIR/assets/weasis.deb"; then
            apt-get -f install -y
            log_ok "Weasis instalado a partir do pacote homologado"
            return 0
        fi
        apt-get -f install -y
    fi

    if apt-get install -y weasis 2>/dev/null; then
        log_ok "Weasis instalado; configuração de usuário não alterada"
        return 0
    fi

    log_error "Weasis não foi instalado: adicione assets/weasis.deb homologado"
    return 1
}
