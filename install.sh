#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/Dexterrpk/Hrsaj-Deploy.git"
INSTALL_DIR="${HRSJ_INSTALL_DIR:-$HOME/Hrsaj-Deploy}"

if ! command -v git >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y git
fi

if [ -d "$INSTALL_DIR/.git" ]; then
    git -C "$INSTALL_DIR" pull --ff-only
else
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"
[ -f config.env ] || cp config.env.example config.env
chmod +x install.sh start.sh hrsaj_deploy.sh modules/*.sh

echo "Projeto instalado em: $INSTALL_DIR"
echo "Revise $INSTALL_DIR/config.env e execute: $INSTALL_DIR/start.sh"
