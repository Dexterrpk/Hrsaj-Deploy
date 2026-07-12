#!/bin/bash

set_wallpaper() {
    local dir="$SCRIPT_DIR/assets/wallpapers" image user home target
    mkdir -p "$dir"
    image=$(find "$dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | sort | head -n1)
    if [ -z "$image" ]; then
        log_warn "Wallpaper homologado ausente em $dir; configuração atual preservada"
        state_mark_ok wallpaper "preservado: imagem ausente"
        return 0
    fi

    target="/usr/share/backgrounds/hrsaj-$(basename "$image")"
    install -m 0644 "$image" "$target"

    for user in "$ADMIN_USER" "$DEFAULT_USER"; do
        id "$user" >/dev/null 2>&1 || continue
        home=$(getent passwd "$user" | cut -d: -f6)
        if command -v xfconf-query >/dev/null 2>&1 && pgrep -u "$user" xfce4-session >/dev/null 2>&1; then
            sudo -H -u "$user" env DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$user")/bus" \
                xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -n -t string -s "$target" 2>/dev/null || true
        fi
        log_ok "Wallpaper validado para $user sem alterar outros arquivos da HOME"
    done
    state_mark_ok wallpaper "$target"
}
