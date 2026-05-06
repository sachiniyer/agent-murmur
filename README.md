# agent-murmur

Push-to-talk dictation for Linux. Powered by Groq's Whisper API.

Press a key, speak, press it again — your transcript types itself into the focused window.

## Why this exists

I wanted dictation that:

- Works **system-wide** (any focused window — terminal, browser, editor, Slack)
- Runs on **KDE Plasma 6 Wayland** without compositor-specific hacks
- Has near-instant latency (Groq's Whisper Large v3 Turbo at ~216x real-time means a 5-second clip comes back in ~30ms)
- Handles **whispered audio** without falling back to "Thank you" hallucinations
- Stays under ~300 lines of Python so I can actually understand and modify it

Mature commercial tools (Vibe Typer, Wispr Flow, Superwhisper) and other open-source options exist; pick whichever fits. This one is intentionally minimal and Groq-only.

## Features

- **Toggle hotkey** — tap to start, tap again to stop. Implemented via a lock file so the same command both starts and stops recording.
- **Audio normalization** — boosts quiet recordings to Whisper's expected level using 99th-percentile peak normalization. Whisper a sentence and it transcribes cleanly.
- **Per-window typing strategy:**
  - **Wave Terminal** → `xdotool type` via XWayland (Wave's xterm.js drops the first chars from `ydotool` and binds Ctrl+Shift+V to its About dialog)
  - **Other terminals** (Konsole, Alacritty, Kitty, Ghostty…) → `wl-copy` + Ctrl+Shift+V via `ydotool`
  - **Everything else** → `ydotool type`
- **Notifications + audio cues** — a notification when recording starts/finishes plus a short start/stop beep.

## Setup

### Prerequisites

- Kubuntu / Ubuntu 24.04+ (or Debian derivative)
- KDE Plasma 6 Wayland (X11 may work; not tested)
- A Groq API key — [console.groq.com/keys](https://console.groq.com/keys)
- Sudo access for the one-time install

### Install

```bash
git clone https://github.com/sachiniyer/agent-murmur.git
cd agent-murmur
./install.sh
```

The install script will:

1. `apt install` runtime dependencies (ydotool, ydotoold, portaudio19-dev, sox, libnotify-bin, xdotool, x11-utils, wl-clipboard)
2. Install a udev rule to make `/dev/uinput` accessible to the `input` group
3. Add you to the `input` group
4. Enable a `ydotoold` systemd **user** service
5. Create a Python venv at `~/.local/share/dictation/venv` with the runtime deps
6. Install the script to `~/bin/dictation`
7. Create `~/.config/dictation/config` (mode 600) for your API key

### After install

1. **Paste your Groq API key** into `~/.config/dictation/config`:
   ```
   GROQ_API_KEY=gsk_...
   ```
2. **Log out and log back in.** This is required so:
   - Your graphical session picks up `input` group membership (lets `ydotool` reach `/dev/uinput`)
   - The `ydotoold` systemd user service auto-starts
3. **Bind a KDE global shortcut** to `~/bin/dictation`:
   - System Settings → Shortcuts → Custom Shortcuts
   - Edit → New → Global Shortcut → Command/URL
   - Trigger: any single non-modifier key (`Insert`, `F8`, `Pause`, `ScrollLock`, …). Don't use Ctrl/Alt combos — see [Quirks](#quirks).
   - Action command: `/home/YOUR_USERNAME/bin/dictation`

That's it. Press the key, speak, press again.

## Configuration

Single file: `~/.config/dictation/config` (mode 600).

```
GROQ_API_KEY=gsk_...
```

To change the **transcription model**, edit the `transcribe()` function in `dictation`. The default is `whisper-large-v3-turbo`. Available Groq models: `whisper-large-v3-turbo`, `whisper-large-v3`.

## Quirks

### Don't bind a Ctrl+/Alt+ combo as the hotkey

KDE's Custom Shortcut system fires on **press**, not release. If you bind `Ctrl+Alt+R`, the script doesn't know when you let go. By the time it injects keystrokes, your modifier keys may still be physically held — and the first injected char becomes a `Ctrl+H` shortcut, an `Alt+T` menu trigger, etc.

A single non-modifier key (Insert, F8, Pause, ScrollLock) sidesteps this entirely.

### `ydotool` first-char drop

`ydotool type` occasionally drops the first 1–2 characters because the virtual `uinput` device needs a moment to "warm up" after creation. The script adds a 150ms pre-delay before typing, which is usually enough. If you still see drops, increase the `time.sleep(0.15)` in `type_text()`.

### Wave Terminal

Wave is Electron + xterm.js running on XWayland. It has both:
- A first-char drop with `ydotool` (xterm.js focus race)
- A non-standard paste shortcut (Ctrl+Shift+V opens its About dialog rather than pasting)

The script special-cases Wave by routing through `xdotool type` instead, which talks to the X server directly and bypasses both issues.

### `wtype` doesn't work on KDE

KDE's KWin doesn't implement the `zwp_virtual_keyboard_v1` Wayland protocol that `wtype` uses. That's why this project uses `ydotool` (kernel `uinput` injection) instead.

## How it works

```
            ┌─────────────────────────────┐
            │  Press hotkey (e.g. Insert) │
            └──────────────┬──────────────┘
                           │
              KDE fires `dictation`
                           │
                           ▼
            ┌─────────────────────────────┐
            │ /tmp/dictation.lock exists? │
            └────────┬───────────┬────────┘
                  no │           │ yes
                     │           │
                     ▼           ▼
              start recording   send SIGTERM to PID
              write own PID     in lock; this proc exits
              to lock file
                     │
                     │  …user speaks…
                     │
              SIGTERM received
                     │
                     ▼
              save WAV → normalize → POST to Groq
                     │
                     ▼
              detect focused window class (xprop)
                     │
                     ▼
              route to xdotool / wl-copy+ydotool / ydotool
                     │
                     ▼
              clean up lock + temp WAV
```

## License

MIT — see [LICENSE](LICENSE).
