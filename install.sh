#!/usr/bin/env bash
# Install agent-murmur on Ubuntu/Kubuntu with KDE Plasma 6 Wayland.
# Tested on Kubuntu 24.04+. Should work on other Debian/Ubuntu derivatives.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/bin"
VENV_DIR="$HOME/.local/share/dictation/venv"
CONFIG_DIR="$HOME/.config/dictation"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

say() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }

say "Installing apt packages (sudo required)"
sudo apt update
sudo apt install -y \
    ydotool ydotoold \
    portaudio19-dev python3-venv python3-pip \
    libnotify-bin sox \
    xdotool x11-utils wl-clipboard

say "Installing udev rule + adding $USER to input group"
sudo cp "$REPO_DIR/udev/60-uinput.rules" /etc/udev/rules.d/60-uinput.rules
sudo udevadm control --reload-rules
sudo udevadm trigger /dev/uinput
sudo usermod -aG input "$USER"

say "Setting up systemd user service for ydotoold"
mkdir -p "$SYSTEMD_USER_DIR"
cp "$REPO_DIR/systemd/ydotoold.service" "$SYSTEMD_USER_DIR/ydotoold.service"
systemctl --user daemon-reload
systemctl --user enable ydotoold.service || true

say "Creating Python venv and installing dependencies"
mkdir -p "$(dirname "$VENV_DIR")"
python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/python3" -m pip install --upgrade pip
"$VENV_DIR/bin/python3" -m pip install groq openai sounddevice numpy scipy

say "Installing dictation script to $BIN_DIR"
mkdir -p "$BIN_DIR"
install -m 755 "$REPO_DIR/dictation" "$BIN_DIR/dictation"

say "Creating config dir"
mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"
if [[ ! -f "$CONFIG_DIR/config" ]]; then
    cp "$REPO_DIR/config.example" "$CONFIG_DIR/config"
fi
chmod 600 "$CONFIG_DIR/config"

cat <<EOF


┌──────────────────────────────────────────────────────────────────────┐
│  Install complete.                                                   │
│                                                                      │
│  Next steps:                                                         │
│                                                                      │
│  1. Add your API keys to:                                            │
│       $CONFIG_DIR/config                                             │
│       OPENAI_API_KEY  → https://platform.openai.com/api-keys         │
│       GROQ_API_KEY    → https://console.groq.com/keys                │
│                                                                      │
│  2. Log out and log back in. (Required so:                           │
│       - your session picks up the new 'input' group membership       │
│       - the ydotoold systemd user service starts)                    │
│                                                                      │
│  3. Bind a KDE Custom Shortcut to /home/$USER/bin/dictation          │
│     System Settings → Shortcuts → Custom Shortcuts → Edit → New →    │
│     Global Shortcut → Command/URL                                    │
│                                                                      │
│     Recommended hotkey: a single non-modifier key like Insert, F8,   │
│     or Pause. Avoid Ctrl+/Alt+ combos — modifier keys held when      │
│     dictation finishes can eat the first chars of the typed output.  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
EOF
