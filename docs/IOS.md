# iOS（侧载 / 自签 IPA）可行性分析

> 结论先行：**技术可行，分发是主要摩擦**。不上 App Store、只发 IPA 给玩家的路走得通，
> 但"玩家怎么装、装完能活多久"比移植本身更费心。

## 1. 结论

| 目标 | 可行性 | 说明 |
|---|---|---|
| 游戏引擎跑在 iOS（Metal） | ✅ 高 | wgpu-hal 30.0.1 自带 `metal` 后端；winit 0.30 有 iOS 后端 |
| 完整启动器 + 游戏在 iPhone 上玩 | 🟡 中 | 需要新写平台层与触摸 UI，工作量约 2–3 人月 |
| 玩家自行安装（侧载） | 🟡 中 | 签名/续签是门槛，见第 4 节 |
| 像安卓 APK 那样"发个文件就能装" | ❌ 低 | iOS 没有这种自由分发机制 |

## 2. 可直接复用的部分

- `horizon-client-render`：wgpu 渲染、HUD、设置界面；
- `horizon-world` / `horizon-core` / `horizon-protocol` / `horizon-assets`：世界、协议、资源解码；
- `horizon-client` 里与平台无关的游戏循环、菜单、单人/局域网逻辑；
- 已有的 macOS/Linux/Windows 窗口分支（先跑 macOS 桌面版可以验证整条链路）。

## 3. 需要新建的部分

| 模块 | 现有（Android） | iOS 需要 |
|---|---|---|
| 平台层 | `android.rs`（65 KB） | UIWindow + CAMetalLayer + 生命周期 |
| 触摸 UI | `android_control_ui.rs`（359 KB） | UIKit 触摸、软键盘、安全区，重写一套 |
| 存储 | Android Keystore | Keychain |
| 文件 | SAF / 外部存储 | 应用沙盒 + `UIDocumentPicker` |
| 资源准备 | 设备上跑 JVM（`horizon-prepare`） | **电脑上准备 + 导入**（App 内不跑 JVM） |
| 原生模组 | 设备上 cargo 编译 + dlopen | 不可用；wasm 模组可考虑随包 |
| 平台条件编译 | 425 处 `target_os = "android"` | 逐处补 iOS 分支 |

## 4. 分发方式（这是重点）

| 方式 | 谁能装 | 有效期 | 门槛 |
|---|---|---|---|
| **Ad-hoc（自有开发者账号）** | 最多 100 台/年，需先收集设备 UDID 再重签 | 1 年 | $99/年，每加一台设备要重打一次 |
| **TestFlight** | 最多 1 万测试者 | 90 天 | 仍需 Beta 审核；"下载并运行 Minecraft" 很可能被拒 |
| **玩家自签**（AltStore / Sideloadly） | 任何想装的人 | 免费账号 7 天、付费账号 1 年 | 玩家要有一台电脑配合续签 |
| **企业证书** | 不限 | 随时吊销 | 违规（面向公众分发会被封） |
| **TrollStore** | 特定未修补系统版本 | 永久 | 依赖系统漏洞，不可依赖 |

现实建议：**Ad-hoc + 自签两条腿走路**——你用自己的账号给核心玩家打 Ad-hoc 包（≤100 台），
其余玩家给一份自签教程（AltStore/Sideloadly）。

## 5. 技术约束

1. **没有 JIT**：JVM 只能解释执行，慢；因此**不要把 Java 准备流程搬到手机上**，
   改为电脑准备资源后导入（`.starling` 包，安卓版已有"来自电脑的文件"入口）。
2. **禁止 fork/exec**：`Command::new` 的十几处（cargo 编译模组、拉起进程）在 iOS 上全部不可用。
3. **禁止加载未签名代码**：原生模组（.so）走不通，只能砍掉或改成随包编译的 wasm。
4. **后台限制**：切后台会被挂起，下载/准备资源要在前台做完（Android 版有同类逻辑可参考）。
5. **Mojang 资源**：IPA 里同样不能放游戏 jar/assets，必须玩家自己的资源导入。

## 6. 阶段计划（建议）

| 阶段 | 内容 | 预估 |
|---|---|---|
| P0 | macOS 桌面版跑通（验证 Metal 渲染 + 资源 + 世界） | 3–7 天 |
| P1 | iOS 空壳：Metal 画标题屏、能响应触摸 | 1–2 周 |
| P2 | 触摸 UI + 资源导入 + 微软登录（Keychain） | 3–5 周 |
| P3 | 自签/Ad-hoc 打包脚本 + 安装文档 | 3–5 天 |
| P4 | 真机联调（发热、内存、触控手感、局域网） | 2–4 周 |

单人、熟悉这套代码的前提下：**2–3 个月**能到"可玩"；要打磨到接近安卓版体验还要更久。

## 7. 风险清单

- 签名过期导致玩家打不开（Ad-hoc 一年、自签 7 天）→ 需要一套"到期提醒 + 续签"流程；
- iPhone 内存与发热（资源约 1.5 GB，进世界后吃内存）；
- 触摸手感（这套 UI 原本是为安卓设计的）；
- 玩家设备 UDID 收集涉及隐私，要有说明与最小化；
- 苹果随时可能收紧签名政策（历史上多次）。

## 8. 参考

- 同类先例：PojavLauncher 的 iOS 版、Amethyst 等 Java 版启动器，全部靠侧载，无 App Store 版本。
- 本仓库构建脚本：`scripts/build_zh_mac.sh`（Android）；iOS 需要换 Xcode 工具链与 XCFramework 打包。
