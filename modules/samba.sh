#!/bin/bash

install_samba() {
    apt-get install -y samba smbclient cifs-utils || return 1
    local share="/home/$ADMIN_USER/Compartilhado"
    install -d -o "$ADMIN_USER" -g "$ADMIN_USER" -m 0775 "$share"

    local begin='# BEGIN HRSAJ DEPLOY' end='# END HRSAJ DEPLOY' tmp
    tmp=$(mktemp)
    awk -v b="$begin" -v e="$end" '
        $0==b {skip=1; next}
        $0==e {skip=0; next}
        !skip {print}
    ' /etc/samba/smb.conf > "$tmp"
    cat >> "$tmp" <<EOF

$begin
[Compartilhado]
path = $share
browseable = yes
read only = no
guest ok = yes
force user = $ADMIN_USER
$end
EOF
    install -m 0644 "$tmp" /etc/samba/smb.conf
    rm -f "$tmp"
    testparm -s >/dev/null 2>&1 || return 1
    systemctl enable --now smbd >/dev/null 2>&1 || return 1
    state_mark_ok samba "compartilhamento validado sem duplicar configuração"
}
