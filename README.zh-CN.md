# ubuntu-macos-ime

[English](README.md) | [简体中文](README.zh-CN.md)

![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20%2F%2024.04-E95420?logo=ubuntu&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-GNOME-FCC624?logo=linux&logoColor=black)
![Fcitx5](https://img.shields.io/badge/Fcitx5-IME-2ea44f)
![Rime](https://img.shields.io/badge/Rime-中州韵-1f6feb)
![rime-ice](https://img.shields.io/badge/rime--ice-雾凇拼音-0A84FF)
![Style](https://img.shields.io/badge/Style-macOS--like-000000?logo=apple&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow)

**Ubuntu 一键安装的仿 macOS 中文输入方案。**

用开源组件 [Fcitx5](https://fcitx-im.org/) + [Rime](https://rime.im/) + [雾凇拼音 (rime-ice)](https://github.com/iDvel/rime-ice) 在 Ubuntu 上接近 macOS 的中文输入体验——无闭源客户端、无广告、词库本地。

| | |
|---|---|
| **系统** | Ubuntu 22.04 / 24.04（GNOME） |
| **技术栈** | Fcitx5 · Rime · 雾凇拼音 |
| **外观** | 浅色圆角候选栏 · 托盘 `拼`（实心）/ `A`（空心描边） |
| **许可证** | MIT |

---

## 为什么做这个

Ubuntu 默认中文输入常常词库弱、切换别扭，或依赖臃肿的第三方客户端。本项目把成熟开源组件收成一条安装脚本，让你得到：

- **雾凇拼音** 的现代词库与联想
- 安静的 **Shift** 中英切换（不弹嘈杂 OSD）
- 接近 macOS 的候选栏（浅灰面板 + 蓝色选中）
- 菜单栏风格托盘：**拼** 实心 · **A** 空心描边

## 快速开始

```bash
git clone https://github.com/RainHater/ubuntu-macos-ime.git
cd ubuntu-macos-ime
chmod +x scripts/install-apple-like-ime.sh
./scripts/install-apple-like-ime.sh
```

然后 **注销并重新登录一次**，让环境变量与 `im-config` 生效。

### 安装脚本会做什么

1. 安装 Fcitx5、Rime、Lua 插件、CJK 字体等
2. 在 **Ubuntu 22.04** 上启用 [fcitx5-qt-backport PPA](https://launchpad.net/~hrzhu/+archive/ubuntu/fcitx5-qt-backport)，将 `librime` 升到 ≥ 1.8.5（雾凇要求）
3. 用 `im-config` 将输入法框架设为 `fcitx5`
4. 写入会话环境变量（`GTK_IM_MODULE`、`QT_IM_MODULE` 等）
5. 克隆 / 更新 [雾凇拼音](https://github.com/iDvel/rime-ice)
6. 安装 `macOS-ime` 候选栏主题（浅灰 + 蓝选中）
7. 生成托盘图标：**拼**（实心圆角）/ **A**（空心描边）
8. 配置 Shift 只在 Rime 内切 拼/A（不在方案间乱跳）

## 安装后

1. 注销 → 再登录
2. 托盘 Fcitx 右键 → **部署 (Deploy)**（首次约 10–30 秒）
3. `Ctrl + Space` → 选择 **Rime**
4. `F4` → 确认 **雾凇拼音**
5. `Shift` 在 **拼** / **A** 间切换
6. 可选验证 Lua：输入 `rq` → 应出现当天日期

### 验证清单

- [ ] Chrome / VS Code / 终端能输入中文
- [ ] 候选栏为浅色横向，选中为蓝色
- [ ] Shift 切 拼 ↔ A，且不弹 “en / 雾”
- [ ] `F4` 能看到雾凇拼音
- [ ] `rq` 能出日期（说明 librime-lua 正常）

## 使用说明

| 操作 | 快捷键 |
|------|--------|
| 切换输入法 | `Ctrl + Space` |
| Rime 内中英 | `Shift` |
| 方案菜单 | `F4` |
| 图形配置 | `fcitx5-configtool` |

### 更新雾凇词库

```bash
git -C ~/.local/share/fcitx5/rime pull
fcitx5-remote -r
# 或托盘 → 部署
```

写在 `*.custom.yaml` 里的用户覆盖不会被 `git pull` 冲掉。

### 终端 TUI（vim 等）看不到拼音字母

全屏 TUI 可能盖住行内预编辑。改为浮窗显示：

```bash
echo 'PreeditInApplication=False' > ~/.config/fcitx5/conf/rime.conf
fcitx5-remote -r
```

### 重新生成托盘图标

```bash
python3 scripts/make-macos-tray-icons.py
# 然后重启 fcitx5，或开关一次 AppIndicator 扩展
```

## 架构

```
应用 → Fcitx5 → Rime → 雾凇拼音词库
                 ↘ macOS-ime 主题 + 托盘 拼 / A
```

## 配置路径

| 用途 | 路径 |
|------|------|
| 雾凇与用户数据 | `~/.local/share/fcitx5/rime/` |
| 用户覆盖 | `~/.local/share/fcitx5/rime/*.custom.yaml` |
| 外观 / 托盘 | `~/.config/fcitx5/conf/classicui.conf` |
| 预编辑 | `~/.config/fcitx5/conf/rime.conf` |
| 会话环境变量 | `~/.config/environment.d/fcitx5.conf` |
| 候选栏主题 | `~/.local/share/fcitx5/themes/macOS-ime/` |

## 环境要求

- Ubuntu **22.04** 或 **24.04**（其他 Debian 系发行版可自行微调）
- 需要 `sudo` 与网络（apt + 克隆雾凇）
- 建议启用 GNOME AppIndicator 扩展以显示托盘图标

## 已知限制

- **GNOME Wayland** 下部分系统 GTK4 应用仍可能拒绝第三方输入法；X11 会话通常正常。
- 不要同时把 **IBus** 与 **Fcitx5** 都设为活动框架。
- 无法做到「零注销、所有已打开窗口立刻生效」：图形程序启动时已读入 `*_IM_MODULE`。至少需要注销（或重启）一次。
- 首次「部署」目前仍可能要在托盘点一次；后续计划进一步自动化。

## 参与贡献

欢迎 Issue / PR：缺陷反馈、各 Ubuntu 版本踩坑、主题微调、安装脚本加固等。

## 致谢

- [iDvel/rime-ice](https://github.com/iDvel/rime-ice) — 现代中文词库
- [Fcitx5](https://github.com/fcitx/fcitx5) / [fcitx5-rime](https://github.com/fcitx/fcitx5-rime)
- 候选栏风格参考社区 macOS 风 Fcitx5 皮肤（如 [fcitx5-themes-candlelight](https://github.com/thep0y/fcitx5-themes-candlelight)）
- [Fcitx 5 on Wayland](https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland)

## 许可证

[MIT](LICENSE)
