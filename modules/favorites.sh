#!/bin/bash

apply_favorites() {
    # Regra HRSAJ: nunca sobrescrever Bookmarks, Preferences, Local State,
    # sessões, extensões ou qualquer outro conteúdo do perfil do Chrome.
    if [ "${PRESERVE_CHROME_PROFILE:-true}" = "true" ]; then
        log_ok "Perfil e favoritos do Chrome preservados sem alterações"
        return 0
    fi

    log_warn "Alteração de favoritos bloqueada por segurança nesta versão"
    return 0
}
