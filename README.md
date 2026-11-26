# ubuntu-macos-ime

[English](README.md) | [简体中文](README.zh-CN.md)

![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20%2F%2024.04-E95420?logo=ubuntu&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-GNOME-FCC624?logo=linux&logoColor=black)
![Fcitx5](https://img.shields.io/badge/Fcitx5-IME-2ea44f)
![Rime](https://img.shields.io/badge/Rime-中州韵-1f6feb)
![rime-ice](https://img.shields.io/badge/rime--ice-雾凇拼音-0A84FF)
![Style](https://img.shields.io/badge/Style-macOS--like-000000?logo=apple&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow)

**One-command Apple-like Chinese IME for Ubuntu.**

Turn Ubuntu into a macOS-like Chinese typing setup with [Fcitx5](https://fcitx-im.org/) + [Rime](https://rime.im/) + [rime-ice (雾凇拼音)](https://github.com/iDvel/rime-ice) — no proprietary IME, no ads, fully local.

| | |
|---|---|
| **OS** | Ubuntu 22.04 / 24.04 (GNOME) |
| **Stack** | Fcitx5 · Rime · rime-ice |
| **Look** | Light rounded candidate bar · tray `拼` (filled) / `A` (outline) |
| **License** | MIT |

---

## Why

Default Ubuntu Chinese input often feels clumsy: weak dictionaries, awkward switching, or heavy third-party clients. This project wires mature open-source pieces into one installer so you get:

- Modern vocabulary via **rime-ice**
- Quiet **Shift** Chinese/English switch (no noisy OSD)
- Candidate UI close to macOS (light panel + blue highlight)
- Menu-bar style tray icons: **拼** filled · **A** outlined

## Quick start

```bash
git clone https://github.com/RainHater/ubuntu-macos-ime.git
cd ubuntu-macos-ime
chmod +x scripts/install-apple-like-ime.sh
./scripts/install-apple-like-ime.sh
```

Then **log out and log back in** once so environment variables and `im-config` take effect.

### What the installer does

1. Installs Fcitx5, Rime, Lua plugins, CJK fonts
2. On **Ubuntu 22.04**, enables [fcitx5-qt-backport PPA](https://launchpad.net/~hrzhu/+archive/ubuntu/fcitx5-qt-backport) so `librime` ≥ 1.8.5 (required by rime-ice)
3. Sets the IM framework to `fcitx5` via `im-config`
4. Writes session env vars (`GTK_IM_MODULE`, `QT_IM_MODULE`, …)
5. Clones / updates [rime-ice](https://github.com/iDvel/rime-ice)
6. Installs the `macOS-ime` candidate theme (light gray + blue selection)
7. Generates tray icons: **拼** (filled squircle) / **A** (outline squircle)
8. Configures Shift for in-Rime 拼/A switching (not scheme hopping)

## After install

1. Log out → log in
2. Tray → right-click Fcitx → **Deploy** (first time ~10–30s)
3. `Ctrl + Space` → select **Rime**
4. `F4` → confirm **雾凇拼音** (rime-ice)
5. `Shift` toggles **拼** / **A**
6. Optional Lua check: type `rq` → today’s date

### Checklist

- [ ] Chinese works in Chrome / VS Code / terminal
- [ ] Candidate bar is light, horizontal, blue highlight
- [ ] Shift switches 拼 ↔ A without popping “en / 雾”
- [ ] `F4` shows 雾凇拼音
- [ ] `rq` expands to a date (librime-lua OK)

## Usage tips

| Action | Shortcut |
|--------|----------|
| Switch IM | `Ctrl + Space` |
| Chinese ↔ English inside Rime | `Shift` |
| Schema menu | `F4` |
| Open config UI | `fcitx5-configtool` |

### Update rime-ice dictionaries

```bash
git -C ~/.local/share/fcitx5/rime pull
fcitx5-remote -r
# or tray → Deploy
```

User patches in `*.custom.yaml` are kept across pulls.

### Terminal TUI (vim, …) hides preedit

Inline preedit can vanish in fullscreen TUI apps. Use the floating panel instead:

```bash
echo 'PreeditInApplication=False' > ~/.config/fcitx5/conf/rime.conf
fcitx5-remote -r
```

### Regenerate tray icons

```bash
python3 scripts/make-macos-tray-icons.py
# then restart fcitx5 or toggle the AppIndicator extension
```

## Architecture

```
Apps → Fcitx5 → Rime → rime-ice lexicon
                 ↘ macOS-ime theme + tray 拼 / A
```

## Config paths

| Purpose | Path |
|---------|------|
| rime-ice + user data | `~/.local/share/fcitx5/rime/` |
| User patches | `~/.local/share/fcitx5/rime/*.custom.yaml` |
| UI / tray | `~/.config/fcitx5/conf/classicui.conf` |
| Preedit | `~/.config/fcitx5/conf/rime.conf` |
| Session env | `~/.config/environment.d/fcitx5.conf` |
| Candidate theme | `~/.local/share/fcitx5/themes/macOS-ime/` |

## Requirements

- Ubuntu **22.04** or **24.04** (other Debian-based distros may work with tweaks)
- `sudo`, network (apt + git clone rime-ice)
- GNOME AppIndicator extension recommended for the tray icons

## Known limitations

- On **GNOME Wayland**, some system GTK4 apps still refuse third-party IMs; an X11 session is usually fine.
- Do not run **IBus** and **Fcitx5** as active frameworks at the same time.
- A full “zero reboot / zero logout” install is impossible: already-running GUI apps have already read `*_IM_MODULE`. One logout (or reboot) is required.
- Tray “Deploy” still needs one click on first install unless you run deploy manually — we aim to automate this further.

## Contributing

Issues and PRs are welcome — bug reports, Ubuntu version notes, theme tweaks, and install-script hardening especially.

## Credits

- [iDvel/rime-ice](https://github.com/iDvel/rime-ice) — modern Chinese lexicon
- [Fcitx5](https://github.com/fcitx/fcitx5) / [fcitx5-rime](https://github.com/fcitx/fcitx5-rime)
- Theme ideas inspired by community macOS-style Fcitx5 skins (e.g. [fcitx5-themes-candlelight](https://github.com/thep0y/fcitx5-themes-candlelight))
- [Using Fcitx 5 on Wayland](https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland)

## License

[MIT](LICENSE)
