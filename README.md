# agent-murmur

Push-to-talk dictation for Linux. Powered by Groq's Whisper API.

## Features

- **Toggle hotkey** — tap to start, tap again to stop
- **Audio normalization + silence trim** — boosts quiet recordings (whispers) to Whisper's expected level and strips leading/trailing silence
- **AI cleanup pass** — Llama 4 Scout removes filler words and self-corrections after Whisper transcribes
- **Per-window typing** — `xdotool` for Wave Terminal, `wl-copy` + Ctrl+Shift+V for other terminals, `ydotool` everywhere else
- **Session logging** — every transcript pair (raw + cleaned) plus the audio is saved to `~/.local/share/dictation/sessions/` for later analysis
- **Notifications + audio cues** on start/stop

## Install

Tested on Kubuntu 24.04+ / KDE Plasma 6 Wayland.

```bash
git clone https://github.com/sachiniyer/agent-murmur.git
cd agent-murmur
./install.sh
```

After install:

1. **Add your Groq API key** to `~/.config/dictation/config` — get one at [console.groq.com/keys](https://console.groq.com/keys)
2. **Log out and log back in** — required for `input` group membership and the `ydotoold` user service
3. **Bind a KDE global shortcut** to `~/bin/dictation` — System Settings → Shortcuts → Custom Shortcuts → Edit → New → Global Shortcut → Command/URL. Use a single non-modifier key (Insert, F8, Pause); avoid Ctrl/Alt combos.

## License

MIT
