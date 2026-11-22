# 关于本发行版（与上游的差异、合规说明）

本仓库与 Release **只分发汉化层和我们自己构建的 APK**，不含 Minecraft 游戏本体资源。

## APK 里有什么

- `lib/arm64-v8a/lib*.so`：上游 MIT 代码的本地化构建；
- `assets/lowbudget.zip`：本项目自己的皮肤包 + 合并字体 + 字体许可证；
- `assets/StarlingVisuals.zip`、`assets/prepare-kit.zip`、`classes.dex`、`res/`：上游 MIT 内容。

## APK 里特意没有的东西

| 内容 | 原因 |
|---|---|
| Mojang 的游戏资源（`bedrock-controls.zip`、游戏 jar/assets、官方贴图） | Minecraft EULA 不允许再分发；首次启动时由应用从 Mojang 官方地址下载 |
| Java 运行时（OpenJDK 25，约 36 MB） | 上游也是运行时下载；应用会用内置 SHA-256 校验后运行，用完删除。OpenJDK 为 GPLv2 + Classpath Exception |

v0.9.0-zh-cn.1 曾把上述两项打进 APK，已撤回；本地保留该版本仅作存档，不再分发。

## 字体

- Noto Sans SC（SIL OFL 1.1，Adobe / Google），与 Geist 的字重合并；
- Geist / Geist Mono（SIL OFL 1.1，The Geist Project Authors）。

许可证全文见 [fonts/OFL.txt](fonts/OFL.txt)；APK 内也随附
（`assets/minecraft/font/OFL-NotoSansSC.txt`、`OFL-Geist.txt`、`assets/diagnostic-fonts/OFL-Geist.txt`）。

## 语言文件

`i18n/zh_cn.json` 与 `packaging/minecraft-zh_cn.json` 以 Minecraft 的英文原文为键，
在官方简体中文译文基础上整理、补充与机器翻译修订，仅供学习交流；
原文与官方译文版权归 Mojang 与原译者所有。

## 非官方

本项目是社区汉化，与 Mojang、Microsoft、Starling 及 Horizon 项目**没有隶属关系**。
“Minecraft” 是 Mojang 的商标；Microsoft 账户登录使用的是公开的 OAuth 设备码流程。
