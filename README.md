# agent-murmur

Push-to-talk dictation for Linux. Powered by ElevenLabs Scribe v2 (best-in-class WER + built-in disfluency removal).

## Features

- **Toggle hotkey** — tap to start, tap again to stop
- **Audio normalization + silence trim** — boosts quiet recordings (whispers) to a usable level and strips leading/trailing silence
- **Filler removal** — Scribe v2's `no_verbatim=true` strips "um", "uh", and false starts as part of transcription (no separate cleanup pass)
- **Per-window typing** — `xdotool` for Wave Terminal, `wl-copy` + Ctrl+Shift+V for other terminals, `ydotool` everywhere else
- **Session logging** — every transcript and the audio is saved to `~/.local/share/dictation/sessions/` for later analysis
- **Notifications + audio cues** on start/stop

## Install

Tested on Kubuntu 24.04+ / KDE Plasma 6 Wayland.

```bash
git clone https://github.com/sachiniyer/agent-murmur.git
cd agent-murmur
./install.sh
```

After install:

1. **Add your ElevenLabs API key** to `~/.config/dictation/config` — get one at [elevenlabs.io/app/settings/api-keys](https://elevenlabs.io/app/settings/api-keys)
2. **Log out and log back in** — required for `input` group membership and the `ydotoold` user service
3. **Bind a KDE global shortcut** to `~/bin/dictation` — System Settings → Shortcuts → Custom Shortcuts → Edit → New → Global Shortcut → Command/URL. Use a single non-modifier key (Insert, F8, Pause); avoid Ctrl/Alt combos.

## License

MIT
