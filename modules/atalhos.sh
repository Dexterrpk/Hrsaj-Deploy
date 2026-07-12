#!/bin/bash

_desktop_dir_for_user() {
    local username="$1" home_dir result=""
    home_dir=$(getent passwd "$username" | cut -d: -f6)
    [ -n "$home_dir" ] || home_dir="/home/$username"
    if command -v xdg-user-dir >/dev/null 2>&1; then
        result=$(sudo -H -u "$username" env HOME="$home_dir" xdg-user-dir DESKTOP 2>/dev/null || true)
    fi
    if [ -z "$result" ] || [ "$result" = "$home_dir" ]; then
        if [ -d "$home_dir/Área de Trabalho" ]; then result="$home_dir/Área de Trabalho";
        elif [ -d "$home_dir/Área de trabalho" ]; then result="$home_dir/Área de trabalho";
        else result="$home_dir/Desktop"; fi
    fi
    printf '%s\n' "$result"
}

_trust_desktop_launcher() {
    local username="$1" launcher="$2" home_dir uid runtime
    home_dir=$(getent passwd "$username" | cut -d: -f6)
    uid=$(id -u "$username")
    runtime="/run/user/$uid"
    chmod 0755 "$launcher"
    chown "$username:$username" "$launcher"
    if [ -S "$runtime/bus" ] && command -v gio >/dev/null 2>&1; then
        sudo -H -u "$username" env HOME="$home_dir" XDG_RUNTIME_DIR="$runtime" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime/bus" \
            gio set "$launcher" metadata::trusted true 2>/dev/null || true
    fi
}

create_desktop_shortcuts() {
    local users=("$ADMIN_USER" "$DEFAULT_USER")
    local apps=(google-chrome.desktop firefox.desktop anydesk.desktop weasis.desktop libreoffice-calc.desktop libreoffice-writer.desktop)
    local username app source dest desktop_dir changed=0 failures=0

    for username in "${users[@]}"; do
        id "$username" >/dev/null 2>&1 || continue
        desktop_dir=$(_desktop_dir_for_user "$username")
        mkdir -p "$desktop_dir"
        chown "$username:$username" "$desktop_dir"
        for app in "${apps[@]}"; do
            source="/usr/share/applications/$app"
            dest="$desktop_dir/$app"
            [ -f "$source" ] || continue
            if [ -f "$dest" ] && cmp -s "$source" "$dest"; then
                _trust_desktop_launcher "$username" "$dest"
                continue
            fi
            install -o "$username" -g "$username" -m 0755 "$source" "$dest" || { failures=$((failures+1)); continue; }
            _trust_desktop_launcher "$username" "$dest"
            changed=$((changed+1))
        done
    done

    [ "$failures" -eq 0 ] || return 1
    state_mark_ok shortcuts "$changed alteração(ões)"
}
