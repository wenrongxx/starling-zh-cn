# 关于本发行版（与上游的差异、合规说明）

本仓库与 Release 只分发汉化层和我们自己构建的 APK，**不含 Minecraft 游戏本体资源**。

## 许可证总览

| 组件 / 内容 | 许可证 | 版权 / 来源 |
|---|---|---|
| 上游 Starling / Horizon 代码（`lib*.so`、`prepare-kit.zip`、`StarlingVisuals.zip`） | MIT | Ludovic Marie 与 Horizon 贡献者 |
| 简体中文汉化层（`i18n/`、语言文件、文档） | MIT | wenrongxx |
| OpenJDK 25（APK 内置） | GPLv2 + Classpath Exception | OpenJDK / AngelAuraMC，见 `third_party/jre25/` |
| Noto Sans SC / Geist 字体 | SIL OFL 1.1 | Adobe / Google / The Geist Project，见 `fonts/OFL.txt` |
| Minecraft 游戏资源与官方译文 | 不随本项目分发；版权归 Mojang | Mojang |

整体许可见 [LICENSE](LICENSE)（MIT）。

## APK 里有什么

- `lib/arm64-v8a/lib*.so`：上游 MIT 代码的本地化构建；
- `assets/lowbudget.zip`：本项目自己的皮肤包 + 合并字体 + 字体许可证；
- `assets/jre25-android-arm64.tar.xz`：OpenJDK 25（Android arm64 构建），**原样分发**，
  附 GPLv2 + Classpath Exception 许可证（见 `third_party/jre25/` 与 APK 内 `assets/licenses/`）；
- `assets/StarlingVisuals.zip`、`assets/prepare-kit.zip`、`classes.dex`、`res/`：上游 MIT 内容。

## APK 里特意没有的东西

| 内容 | 原因 |
|---|---|
| Mojang 的游戏资源（`bedrock-controls.zip`、游戏 jar/assets、官方贴图） | Minecraft EULA 不允许再分发；首次启动时由应用从 Mojang 官方地址下载 |

> v0.9.0-zh-cn.1 曾把 Mojang 的触控按钮贴图打进 APK，已撤回；本地保留存档，不再分发。

## Java 运行时（OpenJDK 25）

- 来源：AngelAuraMC 的 Android 构建，release `download_jre25`（未修改，原样重新分发）；
- 许可：GPLv2 + Classpath Exception，全文见 `third_party/jre25/GPLv2.txt`、
  `CLASS-PATH-EXCEPTION.txt`、`ADDITIONAL_LICENSE_INFO.txt`；
- 对应源码：<https://github.com/openjdk/jdk>，构建脚本与补丁见
  <https://github.com/AngelAuraMC/angelauramc-openjdk-build>；
- 校验：应用启动时会核对 SHA-256 `d3eb7afe…ce4c37`，只用于在本机准备游戏文件，用完删除。

之所以内置而不是首次运行时下载：国内网络拉取 36 MB 的运行时非常慢，内置可以让首次设置直接开始。

## 字体

- Noto Sans SC（SIL OFL 1.1，Adobe / Google），与 Geist 的字重合并；
- Geist / Geist Mono（SIL OFL 1.1，The Geist Project Authors）。

许可证全文见 [fonts/OFL.txt](fonts/OFL.txt)；APK 内也随附
（`assets/minecraft/font/OFL-NotoSansSC.txt`、`OFL-Geist.txt`、`assets/diagnostic-fonts/OFL-Geist.txt`）。

## 语言文件

`i18n/zh_cn.json` 与 `packaging/minecraft-zh_cn.json` 以 Minecraft 的英文原文为键，
在官方简体中文译文基础上整理、补充与机器翻译修订。
本项目对“整理、补充与修订”的部分以 **MIT** 授权；
其中的 Minecraft 英文原文与官方简体中文译文版权归 Mojang 与原译者，不在本项目授权范围内。

## 非官方

本项目是社区汉化，与 Mojang、Microsoft、Starling 及 Horizon 项目**没有隶属关系**。
“Minecraft” 是 Mojang 的商标；Microsoft 账户登录使用公开的 OAuth 设备码流程。
