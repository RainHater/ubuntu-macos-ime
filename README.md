# Ubuntu 仿苹果中文输入法

用 **Fcitx5 + Rime + 雾凇拼音 + macOS 皮肤** 在 Ubuntu 上获得接近 macOS 的中文输入体验（外观、打字手感、词库准确度）。无需自研输入法。

## 一键安装

```bash
chmod +x scripts/install-apple-like-ime.sh
./scripts/install-apple-like-ime.sh
```

脚本会：

1. 安装 Fcitx5 / Rime / Lua 插件等依赖
2. 在 **Ubuntu 22.04** 上自动启用 [fcitx5-qt-backport PPA](https://launchpad.net/~hrzhu/+archive/ubuntu/fcitx5-qt-backport)，将 librime 升到 ≥ 1.8.5（雾凇要求）
3. 将默认输入法框架设为 `fcitx5`
4. 写入会话环境变量
5. 部署 [雾凇拼音 (rime-ice)](https://github.com/iDvel/rime-ice)
6. 候选栏使用 `Material-Color-blue`（稳定、无白边）
7. 状态栏图标：中文 `拼`（实心圆角框）、英文 `ABC`（空心描边框）
8. 横向候选、行内预编辑、Shift 中英切换、每页 9 个候选

## 安装后必做

1. **注销并重新登录**（环境变量与 `im-config` 才生效）
2. 托盘键盘图标右键 → **部署 (Deploy)**（首次 10–30 秒）
3. `Ctrl + Space` 切到 Rime；按 `F4` 确认方案为「雾凇拼音」
4. 用 `Shift` 临时切换中英文
5. 可选验证 Lua：输入 `rq`，应出现当前日期

## 验证清单

- [ ] Chrome / VS Code / 终端能输入中文
- [ ] 候选栏为 macOS 浅色横向样式
- [ ] Shift 可切中英；长句联想正常
- [ ] `F4` 可见「雾凇拼音」
- [ ] 输入 `rq` 能出日期（说明 librime-lua 正常）

## 常用调整

### 候选栏主题

默认 `Material-Color-blue`。若仍想用仿 macOS 皮肤，可在 `~/.config/fcitx5/conf/classicui.conf` 改 `Theme=`，然后 `fcitx5-remote -r`。

### 状态栏 拼 / ABC

由自定义托盘图标（`scripts/make-macos-tray-icons.py`）与 `rime_ice.custom.yaml` 的 `switches/@0/states: [ 拼, ABC ]` 控制：`拼` 为实心圆角框，`ABC` 为空心描边框。`Shift` 切换中英时托盘应在两者间变化。若托盘仍是键盘图标，确认已注销重登，且 GNOME 扩展 `ubuntu-appindicators` 已启用。

### 终端 TUI 看不到拼音字母

行内预编辑在 vim 等全屏程序里可能被覆盖。改为浮窗显示：

```bash
echo 'PreeditInApplication=False' > ~/.config/fcitx5/conf/rime.conf
fcitx5-remote -r
```

### 更新雾凇词库

```bash
git -C ~/.local/share/fcitx5/rime pull
fcitx5-remote -r
# 或托盘右键「部署」
```

用户覆盖写在 `~/.local/share/fcitx5/rime/default.custom.yaml`，不会被 `git pull` 冲掉。

### 图形配置

```bash
fcitx5-configtool
```

## 架构

```
应用 → Fcitx5 → Rime → 雾凇拼音词库
              ↘ Material-Color-blue 候选栏 + 托盘「拼/ABC」
```

## 关键文件位置

| 用途 | 路径 |
|------|------|
| 雾凇配置 / 词库 | `~/.local/share/fcitx5/rime/` |
| 用户覆盖 | `~/.local/share/fcitx5/rime/default.custom.yaml` |
| 外观 / 托盘文字 | `~/.config/fcitx5/conf/classicui.conf` |
| 拼/ABC 状态名 | `~/.local/share/fcitx5/rime/rime_ice.custom.yaml` |
| 预编辑 | `~/.config/fcitx5/conf/rime.conf` |
| 环境变量 | `~/.config/environment.d/fcitx5.conf` |

## 已知限制

- **GNOME Wayland** 下部分系统 GTK4 应用可能无法用第三方输入法；X11 会话通常无此问题。
- 不要同时启用 IBus 与 Fcitx5 作为活动框架，以免冲突。
- Ubuntu 22.04 必须用较新的 librime；脚本已处理。若不用脚本，请自行添加上述 PPA，或改用 Flatpak 版 Fcitx5。

## 参考

- [iDvel/rime-ice](https://github.com/iDvel/rime-ice)
- [thep0y/fcitx5-themes-candlelight](https://github.com/thep0y/fcitx5-themes-candlelight)
- [Fcitx5 Wayland 说明](https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland)
