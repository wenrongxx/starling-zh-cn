# Starling 简体中文汉化（Starling 0.9.0 / Horizon 26.3）

> 非官方汉化工程：把 [Starling](https://github.com/starling-client/starling)（Horizon 的安卓启动器 + Minecraft Java 版 Rust 实现）
> 的启动器界面、设置、向导与游戏内菜单翻成简体中文，并修掉几个和中文相关的功能性 bug。
>
> 基于上游 MIT 许可二次分发；与 Mojang / Microsoft 无关。

## 下载

到 [Releases](../../releases) 下载 `starling-0.9.0-arm64-v8a-zh-cn-built-r13.apk`，覆盖安装即可（arm64-v8a，Android 8+）。

## 这个版本做了什么

| 方面 | 内容 |
|---|---|
| 启动器界面 | 侧边栏、开始游戏、模组、资源包、光影、已安装、设置、皮肤、账户、诊断等全部页面中文化 |
| 设置向导 | 登录、离线档案、文件卡片、下载与准备页（含缺字修复） |
| 游戏内菜单 | 选项、语言、资源包、控制、音乐、辅助功能等简洁版设置页 |
| 微软登录 | 改用旧版 MSA 设备码流程（`login.live.com/oauth20_connect.srf`），登录页自动带出代码；登录后浏览器不再报 `invalid_request` |
| 中文渲染 | 字体替换为 Noto Sans SC 合并字体；图集字形区域扩容，修掉“切出去再回来整片缺字” |
| 语言设置 | 默认语言真正存成 `zh_cn`，语言列表不会再出现“界面中文、选中 English” |

完整改动见 [CHANGES.md](CHANGES.md)；每轮的来龙去脉见 [docs/ENGINEERING_LOG.md](docs/ENGINEERING_LOG.md)。

## 仓库内容

```
i18n/i18n_zh.rs              启动器词库（ZH 精确表 + ZH_EXTRA 子串表）
i18n/zh_cn.json              内置语言文件（assets/horizon/lang/zh_cn.json）
packaging/minecraft-zh_cn.json  皮肤包语言文件（必须与上面那份保持一致）
packaging/pack.mcmeta        语言声明（zh_cn / en_us），语言列表靠它
scripts/build_zh_mac.sh      macOS 上交叉编译 libhorizon_android.so
docs/HANDOVER.md             构建、装机、调试的完整说明
docs/ENGINEERING_LOG.md      每轮改了什么、怎么验证、遗留问题
docs/HANDOVER_PROMPT.md      继续这个项目时的速查
THIRD_PARTY_NOTICES.md       上游的第三方声明（原样保留）
```

## 构建

1. 准备上游源码树与 Rust、Android NDK r27c（脚本会检查，缺了会自己下）。
2. **字体**：把 `crates/horizon-theme/fonts/Geist-{Regular,Medium,SemiBold}.ttf` 与 `GeistMono-Regular.ttf`
   换成 Noto Sans SC（可只保留常用字以减小体积）合并 Geist 字重的字体；不换的话中文会显示成方框。
   字体不在仓库里（体积 + SIL OFL 授权），Release 的 APK 已内置。
3. 应用语言文件：把 `i18n/zh_cn.json` 放到 `crates/horizon-client/assets/horizon/lang/zh_cn.json`，
   `packaging/minecraft-zh_cn.json` 放到 `packaging/lowbudget/pack/assets/minecraft/lang/zh_cn.json`。
4. `bash scripts/build_zh_mac.sh`，产物是 `target/aarch64-linux-android/fast/libhorizon_android.so`。
5. 替换 APK 里的 `lib/arm64-v8a/libhorizon_android.so`、重建 `assets/lowbudget.zip`，`zipalign` + `apksigner` 签名。

## 已知问题

- 简洁版设置里仍有少量原生英文（如 `Auto Sprint` 之外的个别按键名），属于上游 Horizon 新增功能。
- “Horizon 设置”页的页面说明已改为只显示在底部说明条（之前会浮在按钮上）。
- 微软登录依赖微软自家客户端 id `00000000402b5328`；若微软调整旧版设备码流程，登录可能需要再适配。

## 许可

代码与文档沿用上游 **MIT**（见 [LICENSE](LICENSE)）；第三方组件见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
字体（Noto Sans SC）为 SIL Open Font License 1.1，来自 Google Fonts。

## 致谢

- [starling-client/starling](https://github.com/starling-client/starling) 与上游 Horizon 项目
- Noto Sans SC（Google Fonts）
