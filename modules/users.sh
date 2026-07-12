#!/bin/bash

_ensure_user() {
    local username="$1" password="$2" admin="${3:-false}"
    if id "$username" >/dev/null 2>&1; then
        log_ok "Usuário $username já existe; senha preservada"
    else
        useradd -m -s /bin/bash "$username" || return 1
        printf '%s:%s\n' "$username" "$password" | chpasswd || return 1
        log_ok "Usuário $username criado"
    fi
    if [ "$admin" = true ] && ! id -nG "$username" | tr ' ' '\n' | grep -qx sudo; then
        usermod -aG sudo "$username" || return 1
    fi
}

create_users() {
    _ensure_user "$ADMIN_USER" "$ADMIN_PASS" true || return 1
    _ensure_user "$DEFAULT_USER" "$DEFAULT_PASS" false || return 1
    state_mark_ok users "contas validadas sem redefinir senhas"
}
