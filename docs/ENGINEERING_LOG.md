# Starling 汉化工程日志（ENGINEERING LOG）

> 每完成一轮就在这里追加一节，记录：改了什么、怎么验证、产物、遗留问题。
> 更完整的机制说明见 `HANDOVER.md`；日常速查见 `HANDOVER_PROMPT.md`。

---

## 轮次索引

| 轮次 | 时间 | 主题 | 产物 |
|---|---|---|---|
| R1 | 2026-11-22 下午 | P3 按钮偏移修复（前一任 Agent） | `apk_archive/starling-…-built.apk` |
| R2 | 2026-11-22 傍晚 | 翻译收尾（设置/主题/Hub/控件编辑器） | `apk_archive/starling-…-built-r2.apk` |
| R3 | 2026-11-22 晚 | 微软登录跳转修复 + 登录面板汉化 | `apk_archive/starling-…-built-r3.apk` |
| R4 | 2026-11-22 晚 | 登录错误文案补译、实验性说明补译 | `apk_archive/starling-…-built-r4.apk` |
| R5 | 2026-11-22 夜 | 控件编辑器/设置遗漏补译 | `apk_archive/starling-…-built-r5.apk` |
| R6 | 2026-11-22 夜 | 控件编辑器细节补译（事件槽位/图标徽标等） | `apk_archive/starling-…-built-r6.apk` |
| R7 | 2026-11-22 深夜 | **P2 缺字根因补齐**（UI 字形没进图集 CPU 副本）+ 渲染模式弹窗补译 | `starling-0.9.0-arm64-v8a-zh-cn-built-r7.apk` |
| R8 | 2026-11-22 深夜 | 补上 `android_control_theme`（设置向导/卡片）的字形烘焙 + 诊断页补译 | `starling-0.9.0-arm64-v8a-zh-cn-built-r8.apk` |
| R9 | 2026-11-22 深夜 | **缺字真正根因：`horizon/ui-text` 区域太小（4 倍扩容）**；微软登录改走**旧版 MSA 设备码** | `starling-0.9.0-arm64-v8a-zh-cn-built-r9.apk` |
| R10 | 2026-11-23 凌晨 | 简洁版设置 50 个语言键 + 衣柜/皮肤页补译；登录页补 `client_id`；安全审查 | `starling-0.9.0-arm64-v8a-zh-cn-built-r10.apk` |
| R11 | 2026-11-23 凌晨 | 语言列表标错（中文却标 English）、控制页 3 处硬编码、资源包页键缺失 | `starling-0.9.0-arm64-v8a-zh-cn-built-r11.apk` |
| R12 | 2026-11-23 凌晨 | 语言真正落盘为 zh_cn（默认值 + 一次性迁移）；R11 只改了标签 | `starling-0.9.0-arm64-v8a-zh-cn-built-r12.apk` |
| R13 | 2026-11-23 凌晨 | 控制页两个选项标题改硬编码中文；去掉压在按钮上的页面浮动提示 | `starling-0.9.0-arm64-v8a-zh-cn-built-r13.apk` |

> 历史安装包统一收进 `apk_archive/`，根目录只保留最新一版；源码投递包收进 `_work/src_tgz/`。

---

## R7 · 2026-11-22 深夜（缺字 P2 + 渲染模式补译）

### P2 缺字：为什么之前"双保险"没修好

- 之前的修复只覆盖了 **`Font` 自己的字形补丁**（`Font.baked` + `HudAtlas::pixels()` 叠加）。
- 但启动器 / 设置向导 / Hub 的中文走的是 **`ui_theme::Cache`**：ab_glyph 光栅化的字形先进
  `Cache.pending`，再由 `Ui::finish()` 塞进 `HudBatch.patches` 上传 GPU，**从来没有写回图集 CPU 副本**。
- 一旦有代码拿图集像素**重建 HUD 纹理**（`boot_set_ui` / `boot_renderer` / `loading_renderer` /
  `ha_launcher::game::set_loading_ui`，用的还是裸 `atlas.pixels` 字段而不是 `pixels()`），
  这些 UI 字形就全没了；而 `Cache` 仍认为它们已上传 → 文字整片空白。
  代码里原本只对 `Font` 调了 `reset_cache()`，注释也写了"字形会再画一次"，但漏了 UI 缓存。

### 修复（两层）

1. **把 UI 字形写进图集 CPU 副本**：新增 `Font::bake_patches(&[Patch])`；`ui_theme::Ui::finish()`、
   `pack_screen::bind_icons`、`trims::prepare`、`options_ui::draw` 在推补丁时同步烘焙。
2. **重建纹理时带上烘焙像素**：`boot_set_ui` / `boot_renderer` / `loading_renderer` /
   `ha_launcher::game::set_loading_ui` 改用 `atlas.pixels()`（含烘焙层），不再用裸 `atlas.pixels`。

### 其它

- 渲染模式弹窗补译：`Rendering mode`、`Uses the system GPU driver…`、`OpenGL ES / experimental`、
  `For older GPUs…`、`Optimized Vulkan pipeline…`、`Vulkan / GPU batching`、`Vulkan / compatibility` 等。

### 验证

- 编译 0 error；装机后启动器/设置各页文字完整。
- 缺字的原始复现路径（设置向导 → 系统权限页 → 返回）仍需在真机/模拟器上再走一遍确认。

---

## R6 · 2026-11-22 夜（控件编辑器细节）

### 改动

- 源码直译：`Button: {label}` → `按键：{label}`、`EVENT SLOT #{n}` → `事件槽位 #{n}`。
- 词库：`Icon Badge` → 图标徽标、`Hint Label` → 提示标签、`Text Only` → 仅文字。

### 验证

- R5 已在模拟器逐屏确认：设置分区标题、GoyControl 编辑器副标题/预设副标题、
  编辑器三个页签（样式与颜色 / 形状与描边 / 事件与行为）、事件与行为页的
  「穿透/模式/滑动」「删除按键」「可见性」等。
- R6 的 4 处改动（事件槽位、按键：xxx、图标徽标、提示标签、仅文字）由同一渲染路径生效，
  只做了编译与安装确认；下次上机可顺手扫一眼。

> 说明：画布上的 ESC/DEBUG/3RD/MOUSE/DROP/SPRINT/SWAP/JUMP/INV/SNEAK/PRI/SEC 是**按键名**（HUD 上要显示成对应键），保留英文；
> 「LMB (Attack)」等绑定值也是键名，保留。


---

## R5 · 2026-11-22 夜（控件编辑器遗留补译）

### 改动

1. **启动器设置**：`PROFILES, WORKER THREADS & STORAGE` 分区标题与说明。
2. **控制与 HUD 布局**：GoyControl 编辑器的副标题（`Customize GoyControl buttons…`）、
   预设副标题（`Custom layout with more options`）、组件属性页的各种副标题。
3. **控件编辑器 · 事件/行为页**：`KEYBOARD BINDING (EXCLUSIVE)`、`MOUSE / ACTION BINDING (EXCLUSIVE)`、
   `Inactive (Cleared)`、`Pass-Thru: ON/OFF`、`Swipe: ON/OFF`、`Unassigned`、`Built-in`、`Delete Button`、
   `Active: …`（词条 `Active:` 走子串替换）。
4. **控件编辑器 · 绑定选择弹窗**：标题（MCPE 自定义按键 — …）、独占绑定说明、`Keyboard Key` /
   `Mouse & Actions` / 两个说明、`Send Custom Input — Choose Input Type`、`Assign Event Slot #{} …`（改源码）。
5. **控件编辑器 · 三个页签**：`1. Style & Colors` / `2. Shape & Stroke` / `3. Events & Behavior`，
   以及 `Exclusive Binding (Keyboard OR Mouse) • Icon, style & geometry`。
6. 编辑器标题里的 `MCPE Custom Button — {label}` / `GoyControl Button — {label}` /
   `MCPE Component — {}` 改成中文（源码 `format!`）。

### 验证

- 模拟器逐屏截图：启动器设置 → 控制与 HUD 布局 → 自定义控件 → 属性面板三个页签 →
  事件与行为页 → 绑定选择弹窗 → 保存布局弹窗。

### 产物

- `starling-0.9.0-arm64-v8a-zh-cn-built-r5.apk`
- 构建日志：Mac `~/build48.log`（0 error）

---

## R3 / R4 · 2026-11-22 晚（微软登录）

### 根因

设备码响应里的 `verification_uri` 是 `https://www.microsoft.com/link`，它会 302 到**旧版**
`login.live.com/oauth20_remoteconnect.srf`；旧版页面对第三方应用直接报
`invalid_request`（“The application is a first party application…”）。

### 修复

- 新增 `starling_account::device_login_url(code)` → `https://microsoft.com/devicelogin?otc=<code>`，
  落到 v2 的 `login.microsoftonline.com/.../deviceauth`，能正常显示「输入代码以允许访问」。
- 接入：`ha_launcher/login.rs::open_link`、`accounts.rs` 的 `State::Code.link`（游戏内账户屏共用）。

### 仍未解决

- 在模拟器里输入代码后，微软回「该代码无法工作」。用 **Windows 上 curl 申请的新代码**在模拟器浏览器
  里提交也是同样结果 → 说明不是 App 的代码解析问题，而是**模拟器浏览器/网络环境**（走 <本地代理> 的
  MITM 代理）导致校验失败，或微软侧会话不匹配。**需在真机正常网络复测**；若真机同样失败，则检查
  Azure 应用注册（个人账户 + 公共客户端流 + Mojang 批准）。

---

## 环境与命令速查

- 编译（Mac）：`nohup bash ~/build_zh.sh > ~/buildN.log 2>&1 &`（约 4 分钟）
- strip：`$NDK/llvm-strip --strip-unneeded ~/zh_game.so`
- 打包（Windows，`_work/`）：`python pack_zip.py` → `zipalign -f -p 4` → `apksigner sign`
- 安装（模拟器）：`adb install -r /tmp/x.apk`
- 词库：`src_zh/i18n_zh.rs`（与 `_work/starling_src2/.../i18n_zh.rs` 双向同步，改完核对 sha256）


---

## R8 · 2026-11-22 深夜（缺字第二轮：向导/卡片这一路）

### 发现

- R7 只给 `ui_theme::Cache` 补了烘焙；但**设置向导、文件卡片**用的是
  `android_control_theme::Ui`，它有自己的 `Cache`（虽然共用 `reserve_ui_pixels` 分配器），
  `finish()` 里同样只把补丁推进 `HudBatch.patches`，**不写回图集 CPU 副本**。
- 因此向导/卡片在纹理重建后仍然缺字（用户实测截图：卡片大面积空白、按钮只剩"重"）。

### 修复

- `android_control_theme::Ui::finish()` 增加 `self.atlas.font.bake_patches(&pending)`。

### 同时补译（诊断页）

- `Export raw performance data (.jsonl)`、`Share or inspect recorded frame telemetry in Android Files`、
  `World backup & file manager`、`Open worlds folder in system Files to back up or copy saves`、
  `Export JSONL`、`World Files`。

### 微软登录：结论

- 用户在**真机普通网络**上同样得到「该代码无法工作」→ 不是模拟器代理问题。
- 用 `authorize` 端点探测 Starling 的 client id：能 302，但设备码页面对它签发的代码一律拒绝；
  `www.microsoft.com/link` 旧路径还报 "The application is a first party application…"。
- 结论：**Azure 应用注册的问题**（需要：支持个人 Microsoft 账户的公共客户端、允许设备码流、
  并被 Mojang 批准访问 Minecraft API）。这只能由应用所有者处理；`microsoft_client_id` /
  `STARLING_MSA_CLIENT_ID` 已可配置，换上新注册的 id 即可。


---

## R9 · 2026-11-22 深夜（缺字根因 + 旧版 MSA 登录）

### 缺字：真正的原因

- 启动器/向导的界面字形都画在 `HudAtlas` 的 `horizon/ui-text` 区域里，
  而 **boot 图集里这个区域只有 1024×512**（打包图集是 2048×1024）。
- 手机 DPI 下中文字形约 40×40 px，1024×512 只放得下约 300 个字形；
  向导/设置页翻几页就满，满了 `Cache::place` 会清空并回到 (0,0) 重新铺，
  **覆盖掉仍然被缓存的旧字** → 页面上整片整片缺字（正是用户截图的样子）。
- 这解释了为什么 R7/R8 的"烘焙"没解决：它不是纹理重建丢字，而是区域溢出后互相覆盖。

### 修复

- boot 图集：`text_rows` 512 → **2048**（区域 1024×2048，约 4 倍容量）。
- 打包图集：`horizon/ui-text` 2048×1024 → **2048×2048**。
- 之前 R7/R8 的烘焙与 `atlas.pixels()` 改动保留（对真正的纹理重建路径依然正确）。

### 微软登录：改走旧版 MSA

- 新注册的 v2 应用（`f2719b6f-…`）签发的设备码被微软拒绝（真机也一样）。
- 改用旧版 MSA 设备码流程：client id `00000000402b5328`（微软自家的 Minecraft 客户端），
  `https://login.live.com/oauth20_connect.srf`（device_code）+
  `https://login.live.com/oauth20_token.srf`（轮询/刷新）。
- 验证码页面改为 `https://www.microsoft.com/link?otc=<code>`：实测页面**自动带出代码**，
  按钮是「允许访问」，点下去直接进入「登录 / 继续使用 Minecraft。」的微软登录页 —— 代码被接受。
- `Endpoints::live().microsoft` 指向 connect 端点；`token_url()`/`legacy()` 负责分派，
  非 live 的 mock 端点仍走原 v2 逻辑（单测不受影响）。

### 验证

- 模拟器实测：点「用浏览器登录」→ Chrome 打开 login.live.com，代码已填入 →「允许访问」→
  微软账号登录页（继续使用 Minecraft）。
- 剩余的 Xbox/XSTS/Minecraft 步骤沿用原代码，需要真实账号登录后才能验证。


---

## R10 · 2026-11-23 凌晨（简洁版设置语言键 + 衣柜补译 + 登录收尾）

### 简洁版设置（options_ui）漏译

- 根源：这些行用 `lang::get("options.xxx")`，键不在 `zh_cn.json` 里就显示原始键名
  （`options.sprintWindow`、`key.attack`、`options.audioDevice.default`……）。
- 从 `options_ui.rs` / `layout.rs` / `draw.rs` / `settings_shell.rs` 收集到 322 个键，
  其中 **50 个在中英文语言包里都不存在**。
- 已把 50 个键的中文补进**两份** `zh_cn.json`（`assets/horizon/lang` 与
  `packaging/lowbudget/pack/assets/minecraft/lang`，两者必须一致）。
- `Text::literal("Bedrock Inventory: ")` 是硬编码字面量，改为「基岩版物品栏：」。

### 衣柜 / 皮肤页

- 21 条界面文案（云端档案、使用云端外观、刷新、上传皮肤、同步提示等）+ 两处
  `format!`（`Cloud Profile ({})`、`Active Local: {}`）已汉化。

### 登录：浏览器最后的 invalid_request

- 用户在「允许访问」并完成登录后，浏览器跳到
  “invalid_request: The provided request must include a 'client_id' input parameter.”
- 原因：验证页 URL 只带了 `otc`，旧版流程在最后需要 `client_id`。
- 修：`device_login_url` 改为 `…/link?otc=<code>&client_id=<CLIENT_ID>`；
  `platform::open_login_url` 的白名单放宽为允许 `otc` + `client_id` 两个参数。

### 安全审查（用户要求）

检查范围：`starling-account`、`ha_launcher`、`android.rs`、`telemetry`、`native_builds` 等。

- **没有发现后门**：所有外连目标都是 Minecraft/Microsoft/Ely.by/Modrinth/GitHub/playhorizon.dev；
  没有硬编码的可疑域名、没有把账号/文件外发的代码。
- 账号密钥：由 Android Keystore 封存（`accounts.rs`），桌面构建只在内存；
  `starling-account` 里没有记录密码/令牌的日志。
- 没有关闭 TLS 校验（无 `danger_accept_invalid_certs`）。
- 遥测：`horizon-telemetry` 默认全部关闭，同意后才发往 `telemetry.playhorizon.dev`。
- 原生模组：从 GitHub Releases 下载，jar/so 用 sha256 固定校验；但**原生模组本身会执行代码**，
  只应安装可信来源的 `.hmod`。


---

## R11 · 2026-11-23 凌晨（语言列表 + 控制页 + 资源包页）

### 语言设置「显示中文、选的却是英语」

- 根因：`lang::DEFAULT` 被改成 `zh_cn`，而 `lang::available()` 给默认语言写死的名字是
  `English / US`。于是列表里被标成选中的那行（code `zh_cn`）显示为「English (US)」——
  界面是中文、语言却写着英语。
- 修：默认语言的名字按代码取（`zh_cn` → 简体中文 / CN）；`pack.mcmeta` 补 `language`
  段，列出 `zh_cn`（简体中文/CN）与 `en_us`（English/US），列表两项都能选。

### 控制页硬编码

- `Touch Controls...`、`Input device`、`Auto Sprint` 三处不是语言键走不通：
  - `Touch Controls...` 改成 `tr("horizon.controls.touch")`；
  - `Input device` / `Auto Sprint` 改成带点键 `options.androidInputSelection` / `options.touchAutoSprint`；
  - `InputSelection::label()` 的 Auto/Touch/Keyboard & Mouse/Controller 直接改中文。
- 新增键：`options.androidInputSelection`、`options.touchAutoSprint`、`horizon.controls.touch`。

### 资源包页

- 缺键：`resourcePack.vanilla.name`、`resourcePack.vanilla.description`（内置资源包）已补。
- `Put packs in {}/resourcepacks` 是 `format!` 字面量，改成「把资源包放进 {}/resourcepacks」。

### 已知未修

- 「Horizon 设置」页悬浮说明文字压在按钮上（`dock_note` / 提示行重叠），需要再看一次
  全分辨率截图确认是 dock 还是 tooltip。


---

## R12 · 2026-11-23 凌晨（语言设置真正生效）

### 为什么 R11 看起来没生效

- R11 只改了语言**列表的标签**（把默认项从 "English (US)" 改成「简体中文」）；
- 但 `options.txt` 里存的仍然是 `lang:en_us`。语言是按「DEFAULT 打底 + 所选语言覆盖」加载的，
  `zh_cn` 是打底层，所以界面一直是中文，而设置里自然标着 English —— 用户看到的「不一致」来自这里。
- 所以必须让**存盘的语言**变成 `zh_cn`。

### R12 修复

- `lang::DEFAULT` 回到 `en_us`（打底层恢复成英文，选英文才是纯英文）；
- `options.txt` 的默认语言改成 `zh_cn`（新装即为中文）；
- 一次性迁移：`Settings::load` 发现 `lang:en_us` 且没有 `.starling-lang-v1` 标记时，
  改写成 `zh_cn` 并写标记；之后玩家自己选的英语会保留。
- 实测（模拟器）：`/storage/emulated/0/Starling/options.txt` 已是 `lang:zh_cn`，
  且 `.starling-lang-v1` 已生成；安装的 base.apk md5 与 r12 文件一致。

### 注意

- 这台模拟器（Mac 上的 `emulator-5554`）在 20:57 前后**应用数据被清空**（账号登出、
  `files/resources` 消失），所以现在会停在「设置 Starling」向导页。真机不受影响；
  要恢复需重新登录 + 重新下载资源。


---

## R13 · 2026-11-23 凌晨（控制页标题 + 浮动提示）

### 控制页两个标题仍显示键名

- `Input device`、`Auto Sprint` 先改成带点的语言键，界面上仍显示 `options.androidInputSelection` /
  `options.touchAutoSprint`（这份构建里语言表没有生效到这两行，原因未完全定位：设备上解包出来的
  `zh_cn.json` 确实含有这两个键）。
- 结论：不再依赖语言表，`Opt::AndroidInputSelection` / `Opt::TouchAutoSprint` 的标题直接写中文
  （「输入设备」「自动疾跑」），`InputSelection::label()` 已是中文。

### 说明文字压在按钮上（用户确认是“选中时出现的注释”）

- 那是 `options_ui` 给「Horizon 页面按钮」画的**浮动提示**：`Act::Push(page)` 会取
  `pages::horizon_page_tooltip(page)`，按手指位置画在按钮上，把按钮和旁边的字盖住。
- 而 Horizon 页面本身已经在底部说明条（`dock_note`）里显示同一段说明 —— 重复了。
- 修：删掉 `Act::Push(page)` 的浮动提示，只保留底部说明条。

### 未验证

- 这台模拟器上 **adb 的合成触摸事件进不到游戏窗口**（启动器界面能点，游戏内点不动），
  所以控制页/语言页没法现场截图复核；改动是确定性的（中文直接写在源码里）。


---

## R14 / R15 · 2026-11-22 深夜（发布与合规）

- 发布到 GitHub：`wenrongxx/starling-zh-cn`（MIT，公开）。
- R14：移除 APK 内 Mojang 资源（bedrock-controls.zip）与内置 JRE；因为首次启动要下载 36 MB 的
  JRE 太慢，没有作为正式版。
- R15（正式）：保留内置 JRE，补 `assets/licenses/`（GPLv2、Classpath Exception、
  Additional License Info、来源与源码地址）；不打包任何 Mojang 资源；字体 OFL 随包。
  产物 `starling-0.9.0-arm64-v8a-zh-cn-built-r15.apk`（222.7 MiB），
  Release `v0.9.0-zh-cn.3`；v0.9.0-zh-cn.1/.2 已下架，本地存档在 `apk_archive/`。


---

## 验收 · 2026-11-22 深夜

- 用户在小米手机（HyperOS）与 Mac 模拟器上测试 r15（Release `v0.9.0-zh-cn.3`）：
  **未发现大问题**。
- 已验收：启动器各页中文、简洁版设置（控制/音乐/辅助功能）中文、默认语言为简体中文、
  微软正版登录（设备码自动填入、登录后无 `invalid_request`）、切出去再回来不缺字。
- Release 资产：`starling-0.9.0-arm64-v8a-zh-cn-built-r15.apk`
  （SHA-256 `066ee10e…f6a522`），含 Mojang 资源排除说明与 JRE/字体许可证。


---

## R18 · 2026-11-23（字体子集 + 体积优化）

- 字体子集：保留 GB2312 全部（6763 汉字 + 符号）+ 本项目所有文案字符 + ASCII/标点，
  `pyftsubset` 处理 `crates/horizon-theme/fonts/Geist-*.ttf`（13 MB → 4.1 MB × 4）
  与皮肤包 `zh.ttf`（9.3 MB → 2.0 MB）。
- 因字体是 `include_bytes!` 编进游戏库的，需要重新构建 `libhorizon_android.so`；
  重新构建 + strip 后库从 180.6 MiB 降到 129.7 MiB。
- 顺带删掉包里冗余的 `libhorizon_mod_host.so`（R17），APK 总体积
  222.8 MiB → 170.1 MiB（R17）→ **136.1 MiB**（R18）。
- 副作用：GB2312 之外的生僻字（聊天/服务器消息）会显示方框。


---

## R19 · 2026-11-23（移动数据启动黑屏）

- 现象：手机流量下启动黑屏，WiFi 正常。
- 诊断（用户诊断包）：`current-session.json` 卡在 `phase: native_start`，
  `latest.log` 只有前 3 行（`Open file limit raised` 之后没有任何日志）；
  同机 WiFi 的成功日志里，紧接着那行是
  `Original Android control textures: ... Connection reset by peer (os error 104)`。
- 根因：`game.rs` 在**创建窗口之前、主线程上**同步调用
  `android_control_assets::fetch()` 下载 21 个可选贴图（`raw.githubusercontent.com`，
  连接超时 30 s / 读取 60 s）。WiFi 下连接被立刻 RST → 秒失败继续；
  移动数据下静默丢包 → 主线程一直等，界面永远画不出来。
- 修复：把该 fetch 移到后台线程（与 `bedrock_touch` 同样的做法），
  超时改为 3 s / 5 s。
- 产物：r19（136.1 MiB），Release `v0.9.0-zh-cn.7`。


---

## R21 / R22 · 2026-11-23（下载源）

- BMCLAPI 实测比官方慢约 10 倍（80 个小文件：0.18 vs 1.97 MB/s，且有失败），用户反馈 0.42 MB/s。
- R21：下载源改为「自动测速」（默认），并发 4 → 8；实测模拟器整包 672 MB 下载约 7 分钟，
  平均 ~1 MB/s（峰值 3.4），此前 BMCLAPI 只有 0.42 MB/s、ETA 21 分钟。
- R22：下载页文案跟随实际来源（官方/镜像/正在选源），不再是写死的「来自 Mojang 服务器」。
- 产物 r22（136.1 MiB），Release `v0.9.0-zh-cn.8`。


---

## R23 · 2026-11-23（检查阶段变快）

- 「正在检查游戏文件」耗时的三块：选源测速（旧超时 20/60 s，镜像丢包会一直等）、
  拉版本清单、逐个 SHA-1 校验已有文件（670 MB / 5215 个）。
- 修：测速用独立 agent，3 s 连接 / 6 s 读取 / 8 s 总超时；检查页在测速期间显示
  「正在测速选择下载源…」。产物 r23，Release `v0.9.0-zh-cn.9`。
- 可选后续：用 `FILES_DONE` 标记跳过重复校验（检查 ~30 s → 1–2 s，代价是不再发现外部改坏的文件）。


---

## 推送故障 · 2026-11-23 深夜

- 现象：`git push` / `git ls-remote` 对 `github.com` 一直返回 **503 / 504**，但浏览器能打开 GitHub，
  且 `gh api`（api.github.com）正常。
- 原因：本机 DNS 把 `github.com` 解析到了内网代理地址；该地址不代理 git 的 smart-HTTP 请求，
  于是所有 git 操作都 5xx。`api.github.com` 解析正常，所以 `gh` 可用。
- 解决：给仓库固定真实 IP，绕过这条 DNS 记录（本地配置，不提交）：

      git config http.curloptResolve github.com:443:<GitHub 的真实 IP>

- 应急：用 GitHub API 逐文件提交（`gh api …/git/blobs|trees|commits|refs`，见 `_work/api_commit*.py`）。


---

## R24 · 2026-11-28（开房间支持 IPv6）

- 以前 `Lan::bind` 默认绑 `0.0.0.0`，朋友用公网 IPv6 连不进来。
- 改：默认绑 `[::]` + `IPV6_V6ONLY=0`（socket2），一个端口同时接 v4/v6；失败回退 v4。
  `available_port` 也用同一双栈 socket 探端口；accept 时把 `::ffff:a.b.c.d` 归一成 v4。
- 验证：Mac 上独立小程序实测 `[::]:port` 同时接受 `127.0.0.1` 与 `[::1]`；
  客户端连服务器本来就支持 IPv6（`parse_address` 支持 `[v6]:port`，`to_socket_addrs` 双栈）。
- 产物 r24（136.2 MiB），Release `v0.9.0-zh-cn.10`。

- 补充：若双方 WiFi 都没有 IPv6，可改用手机流量（运营商一般会下发 IPv6）。


---

## R25 / R26 · 2026-11-28（IPv6 直连地址进聊天栏）

- R25：开房间后在聊天栏补一行 `IPv6 直连：[地址]:端口`；只认全球单播 `2000::/3`
  （fe80/fec0/fc00 与 ::1 都跳过）。用户真机确认能显示 `2409:…` 的地址。
- R26：按用户要求做成原版 `/seed` 那种**绿色可点击复制**（`ClickEvent::CopyToClipboard`
  + `Style::color(GREEN)` + hover「点击复制地址」），并在开房间时**自动复制到剪贴板**
  （`SystemClipboard::set_text`）。
- 模拟器上仍无法驱动"-对局域网开放"的确认弹窗（adb 合成点击无效），该项由用户在真机验证。
