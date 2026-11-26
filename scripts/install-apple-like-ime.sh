#!/usr/bin/env bash
# Install Fcitx5 + Rime + 雾凇拼音 + macOS theme (Apple-like Chinese IME on Ubuntu).
set -euo pipefail

RIME_DIR="${HOME}/.local/share/fcitx5/rime"
THEMES_DIR="${HOME}/.local/share/fcitx5/themes"
FCITX_CONF_DIR="${HOME}/.config/fcitx5/conf"
ENV_DIR="${HOME}/.config/environment.d"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

log() { printf '\n==> %s\n' "$*"; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "缺少命令: $1" >&2
    exit 1
  }
}

ubuntu_codename() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    echo "${VERSION_CODENAME:-}"
  fi
}

log "安装 Fcitx5 / Rime 依赖"
need_cmd sudo
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
  software-properties-common \
  fcitx5 \
  fcitx5-config-qt \
  fcitx5-rime \
  fcitx5-frontend-gtk3 \
  fcitx5-frontend-gtk4 \
  fcitx5-frontend-qt5 \
  librime-plugin-lua \
  git \
  fonts-noto-color-emoji \
  fonts-noto-cjk

# Ubuntu 22.04 (jammy) ships librime 1.7.x; 雾凇需要 >= 1.8.5
CODENAME="$(ubuntu_codename)"
if [[ "${CODENAME}" == "jammy" ]]; then
  log "检测到 Ubuntu 22.04，启用 fcitx5 backport PPA 以升级 librime"
  sudo add-apt-repository -y ppa:hrzhu/fcitx5-qt-backport
  sudo apt update
  sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    librime1 \
    librime-bin \
    librime-plugin-lua \
    librime-plugin-charcode \
    librime-plugin-octagram \
    fcitx5 \
    fcitx5-rime
fi

log "将默认输入法框架设为 fcitx5"
if command -v im-config >/dev/null 2>&1; then
  im-config -n fcitx5
else
  echo "警告: 未找到 im-config，请手动在「语言支持」中选择 fcitx5" >&2
fi

log "写入会话环境变量"
mkdir -p "${ENV_DIR}"
cat > "${ENV_DIR}/fcitx5.conf" <<'EOF'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
INPUT_METHOD=fcitx
EOF

log "部署雾凇拼音 (rime-ice)"
mkdir -p "$(dirname "${RIME_DIR}")"
if [[ -d "${RIME_DIR}/.git" ]]; then
  git -C "${RIME_DIR}" pull --ff-only || true
elif [[ -d "${RIME_DIR}" ]] && [[ -n "$(ls -A "${RIME_DIR}" 2>/dev/null || true)" ]]; then
  backup="${RIME_DIR}.bak.$(date +%Y%m%d%H%M%S)"
  echo "备份已有 Rime 配置到 ${backup}"
  mv "${RIME_DIR}" "${backup}"
  git clone --depth 1 https://github.com/iDvel/rime-ice.git "${RIME_DIR}"
else
  git clone --depth 1 https://github.com/iDvel/rime-ice.git "${RIME_DIR}"
fi

log "写入 default.custom.yaml（候选数 / Shift 中英）"
cat > "${RIME_DIR}/default.custom.yaml" <<'EOF'
patch:
  schema_list:
    - schema: rime_ice
  menu/page_size: 9
  ascii_composer/switch_key:
    Shift_L: commit_code
    Shift_R: commit_code
EOF

# OSD/tray takes schema name first char; latin mode shows "A"
cat > "${RIME_DIR}/rime_ice.custom.yaml" <<'EOF'
patch:
  schema/name: "拼"
  switches/@0/states: [ 拼, A ]
EOF

mkdir -p "${HOME}/.local/share/fcitx5/inputmethod"
cat > "${HOME}/.local/share/fcitx5/inputmethod/rime.conf" <<'EOF'
[InputMethod]
Name=Rime
Name[zh_CN]=拼
Icon=fcitx-rime
Label=拼
LangCode=zh
Addon=rime
Configurable=True
EOF

log "安装 macOS 主题"
mkdir -p "${THEMES_DIR}"
git clone --depth 1 https://github.com/thep0y/fcitx5-themes-candlelight.git "${TMP_DIR}/themes"
for theme in macOS-light macOS-dark macOS-light-png macOS-dark-png; do
  if [[ -d "${TMP_DIR}/themes/${theme}" ]]; then
    rm -rf "${THEMES_DIR}/${theme}"
    cp -a "${TMP_DIR}/themes/${theme}" "${THEMES_DIR}/"
  fi
done

# Fcitx5 5.1+: Highlight Left/Right=18 on a ~39px asset collapses the
# 9-slice center, so the blue highlight shows a white/panel edge. Shrink margins.
for theme in macOS-light macOS-dark macOS-light-png macOS-dark-png; do
  conf="${THEMES_DIR}/${theme}/theme.conf"
  [[ -f "${conf}" ]] || continue
  python3 - "${conf}" <<'PY'
import re, sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
parts = text.split("[InputPanel/Highlight/Margin]")
if len(parts) < 2:
    raise SystemExit(0)
head, rest = parts[0], parts[1]
idx = rest.find("\n[")
block, tail = (rest[:idx], rest[idx:]) if idx != -1 else (rest, "")
for key, val in (("Left", "10"), ("Right", "10"), ("Top", "8"), ("Bottom", "8")):
    if re.search(rf"^{key}=", block, re.M):
        block = re.sub(rf"^{key}=.*$", f"{key}={val}", block, count=1, flags=re.M)
    else:
        block += f"\n{key}={val}\n"
open(path, "w", encoding="utf-8").write(head + "[InputPanel/Highlight/Margin]" + block + tail)
PY
done

log "安装 Inter 字体并配置接近 macOS 菜单栏的托盘字重"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y fonts-inter fonts-inter-variable >/dev/null
mkdir -p "${HOME}/.config/fontconfig/conf.d"
cat > "${HOME}/.config/fontconfig/conf.d/59-macos-im-tray.conf" <<'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <match target="pattern">
    <test qual="any" name="family">
      <string>MacIMTray</string>
    </test>
    <edit name="family" mode="prepend" binding="strong">
      <string>Inter</string>
      <string>Noto Sans CJK SC</string>
    </edit>
    <edit name="weight" mode="assign">
      <const>medium</const>
    </edit>
  </match>
</fontconfig>
EOF
fc-cache -f >/dev/null 2>&1 || true

log "安装 macOS 风格候选栏主题 (macOS-ime)"
mkdir -p "${THEMES_DIR}/macOS-ime"
cat > "${THEMES_DIR}/macOS-ime/panel.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="40" height="40">
  <rect x="0.5" y="0.5" width="39" height="39" rx="10" ry="10"
        fill="#f0f0f0" fill-opacity="0.92" stroke="#000000" stroke-opacity="0.18" stroke-width="1"/>
</svg>
EOF
cat > "${THEMES_DIR}/macOS-ime/highlight.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="40" height="40">
  <rect x="0" y="0" width="40" height="40" rx="8" ry="8" fill="#0a84ff" stroke="none"/>
</svg>
EOF
cat > "${THEMES_DIR}/macOS-ime/theme.conf" <<'EOF'
[Metadata]
Name=macOS-ime
Version=1.0
Author=typewriting
Description=macOS-like candidate panel
ScaleWithDPI=True

[InputPanel]
NormalColor=#000000b3
HighlightCandidateColor=#ffffff
EnableBlur=False
FullWidthHighlight=False
HighlightColor=#000000b3
HighlightBackgroundColor=#00000000
PageButtonAlignment=Bottom

[InputPanel/Background]
Image=panel.svg
Color=#f0f0f0
BorderColor=#00000000
BorderWidth=0

[InputPanel/Background/Margin]
Left=10
Right=10
Top=10
Bottom=10

[InputPanel/ContentMargin]
Left=4
Right=4
Top=4
Bottom=4

[InputPanel/Highlight]
Image=highlight.svg
Color=#0a84ff
BorderColor=#00000000
BorderWidth=0

[InputPanel/Highlight/Margin]
Left=8
Right=8
Top=8
Bottom=8

[InputPanel/TextMargin]
Left=10
Right=10
Top=6
Bottom=6
EOF

log "配置 classicui：macOS 候选栏 + 托盘字体"
mkdir -p "${FCITX_CONF_DIR}"
cat > "${FCITX_CONF_DIR}/classicui.conf" <<'EOF'
Vertical Candidate List=False
PerScreenDPI=True
WheelForPaging=True
Font="Noto Sans CJK SC Medium 14"
MenuFont="Noto Sans CJK SC Medium 12"
TrayFont="MacIMTray Medium 13"
TrayOutlineColor=#00000000
TrayTextColor=#f5f5f7
# False: use custom 拼/A icons (PreferTextIcon would also force latin to "A")
PreferTextIcon=False
ShowLayoutNameInIcon=False
UseInputMethodLangaugeToDisplayText=True
Theme=macOS-ime
DarkTheme=macOS-ime
UseDarkTheme=False
UseAccentColor=False
EOF

# macOS menu-bar style tray glyphs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/make-macos-tray-icons.py" ]]; then
  python3 "${SCRIPT_DIR}/make-macos-tray-icons.py" || true
  gtk-update-icon-cache -f "${HOME}/.local/share/icons/hicolor" 2>/dev/null || true
fi

cat > "${FCITX_CONF_DIR}/rime.conf" <<'EOF'
PreeditInApplication=False
EOF

log "停止 fcitx5，写入快捷键与 profile（Shift 只切 Rime 中英，不切 en/雾）"
pkill -x fcitx5 2>/dev/null || true
sleep 1
for _ in 1 2 3 4 5; do
  pgrep -x fcitx5 >/dev/null || break
  pkill -9 -x fcitx5 2>/dev/null || true
  sleep 1
done

mkdir -p "${HOME}/.config/fcitx5"
# Clear Shift+Shift_L enumerate (would switch keyboard-us ↔ rime → en/雾)
cat > "${HOME}/.config/fcitx5/config" <<'EOF'
[Hotkey]
TriggerKeys=
EnumerateWithTriggerKeys=False
EnumerateForwardKeys=
EnumerateSkipFirst=False

[Hotkey/EnumerateBackwardKeys]

[Hotkey/PrevPage]
0=Up

[Hotkey/NextPage]
0=Down

[Behavior]
ActiveByDefault=True
ShareInputState=All
PreeditEnabledByDefault=True
# macOS: Shift 中英切换不弹提示
ShowInputMethodInformation=False
showInputMethodInformationWhenFocusIn=False
CompactInputMethodInformation=True
ShowFirstInputMethodInformation=False
DefaultPageSize=9
PreloadInputMethod=True

# GNOME IBus panel/kimpanel steals candidate UI → classicui themes won't show
[Behavior/DisabledAddons]
0=kimpanel
1=ibusfrontend
EOF

PROFILE="${HOME}/.config/fcitx5/profile"
cat > "${PROFILE}" <<'EOF'
[Groups/0]
Name=默认
Default Layout=us
DefaultIM=rime

[Groups/0/Items/0]
Name=rime
Layout=

[GroupOrder]
0=默认
EOF

# Avoid GNOME ibus (libpinyin) fighting fcitx5 and showing "en"
if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us')]" 2>/dev/null || true
fi

log "启动 fcitx5 并触发 Rime 部署"
setsid fcitx5 -d >/dev/null 2>&1 < /dev/null &
sleep 2
if command -v fcitx5-remote >/dev/null 2>&1; then
  fcitx5-remote -s rime 2>/dev/null || true
  fcitx5-remote -r 2>/dev/null || true
fi

cat <<'EOF'

安装完成。

下一步（必须）:
  1. 注销并重新登录（让环境变量与 im-config 生效）
  2. 托盘右键 →「部署」(Deploy)，首次约 10–30 秒
  3. 确认当前为 Rime；按 F4 确认方案为「雾凇拼音」
  4. Shift 在 Rime 内切换 拼/A（不要再用 Shift 切 en/雾）
  5. 候选栏主题为 macOS-ime（浅灰圆角 + 蓝色选中）

验证 Lua: 输入 rq 应能出现当前日期。
EOF
