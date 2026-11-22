# 改动清单

按文件列出这个汉化版相对上游 Starling 0.9.0 / Horizon 26.3 的改动。行号会随上游变化，按主题找即可。

## 1. 启动器界面汉化

### 新增文件

- `crates/horizon-client/src/i18n_zh.rs`
  - `ZH`：精确匹配表（binary_search），约 1400 条；
  - `ZH_EXTRA`：整词边界子串替换表，用于 “Obsidian Purple • Dark • Solid Color” 这类组合串；
  - `tr()` / `tr_owned()` 入口，未命中会打 `i18n_missing:` 日志（logcat 里可查漏翻）。
  - 注意：**带 `{}` 的 format! 词条永远不会命中**，这类文案必须改源码。

### 接入点

- `crates/horizon-client/src/lib.rs`：`pub mod i18n_zh;`
- `crates/horizon-client/src/android_control_theme.rs`：`text_line` / `measure` / `fit_text` 走 `tr()`。
- `crates/horizon-client/src/ui_theme.rs`：`text` / `text_width` 走 `tr()`。

### 源码直译（format! 与动态文案）

`ha_launcher/launcher_pages.rs`、`catalog.rs`、`chooser.rs`、`login.rs`、`documents.rs`、
`account.rs`、`wardrobe.rs`、`platform.rs`、`ha_launcher/mod.rs`、`accounts.rs`、
`title/account.rs`、`android_control_ui.rs`、`android_controls/layout.rs`。

## 2. 游戏内菜单（简洁版设置）

- `crates/horizon-client-render/src/options_ui.rs`
  - 控制页标题：「输入设备」「自动疾跑」「触控操作…」；
  - `Text::literal("Bedrock Inventory: ")` → 「基岩版物品栏：」；
  - 去掉 `Act::Push(page)` 的浮动提示（说明只显示在底部说明条，不再压住按钮）。
- `crates/horizon-client-render/src/pack_screen.rs`：`Put packs in …/resourcepacks` → 「把资源包放进 …/resourcepacks」。
- `crates/horizon-client-render/src/android_controls/layout.rs`：`InputSelection::label()` 中文化。

## 3. 语言文件

两份 `zh_cn.json` 必须保持**完全一致**：

- `crates/horizon-client/assets/horizon/lang/zh_cn.json`（`i18n/zh_cn.json`）
- `packaging/lowbudget/pack/assets/minecraft/lang/zh_cn.json`（`packaging/minecraft-zh_cn.json`）

新增键（约 60 个）：`options.sprintWindow`、`options.quitShortcuts`、`options.operatorItemsTab`、
`options.audioDevice`、`options.graphicsApi*`、`options.textureFiltering*`、`options.exclusiveFullscreen*`、
`options.telemetry`、`key.attack`、`key.use`、`key.keyboard.*`、`Auto Sprint`、`Touch Controls…`、
`resourcePack.vanilla.name/description`、`starling.diagnostics.title` 等。

`packaging/lowbudget/pack/pack.mcmeta` 增加 `language` 段（zh_cn 简体中文 / en_us English），
语言列表靠它列出可选语言。

## 4. 默认语言

- `crates/horizon-client-core/src/lang.rs`：`DEFAULT = "en_us"`（打底层）；
  语言列表里默认项的名字按代码取（`zh_cn` → 简体中文 / CN），不再固定写 “English (US)”。
- `crates/horizon-client-render/src/options_file.rs`：`lang` 默认值 `zh_cn`。
- `crates/horizon-client-render/src/settings.rs`：默认语言 `zh_cn`；
  `Settings::load` 里做一次性迁移——读到 `lang:en_us` 且没有 `.starling-lang-v1` 标记时改写成 `zh_cn`，
  之后玩家自己选的英语会保留。

## 5. 缺字修复（切出去再回来整片空白）

- `crates/horizon-client-render/src/font.rs`：新增 `Font::bake_patches()`，把运行时字形写进图集 CPU 副本；
  `take_patches()` 先烘焙再返回。
- `crates/horizon-client/src/ui_theme.rs`、`android_control_theme.rs`：`finish()` 推补丁时烘焙。
- `crates/horizon-client-render/src/pack_screen.rs`、`trims.rs`、`options_ui/draw.rs`：推补丁前先烘焙。
- `crates/horizon-client-render/src/hud.rs`
  - `boot()` 的界面字形区 `text_rows` 512 → 2048；
  - `horizon/ui-text` 贴图 2048×1024 → 2048×2048。
- 重建 HUD 纹理的入口改用 `atlas.pixels()`（含烘焙层），不再用裸 `atlas.pixels` 字段：
  `game/runtime/loading_window.rs`（`boot_set_ui` / `boot_renderer` / `loading_renderer`）、
  `ha_launcher/game.rs`（`set_loading_ui`）。

## 6. 微软登录（旧版 MSA 设备码）

- `crates/starling-account/src/lib.rs`
  - `CLIENT_ID = "00000000402b5328"`（微软自家 Minecraft 客户端）；
  - `Endpoints::live().microsoft` 指向 `https://login.live.com/oauth20_connect.srf`；
  - `token_url()` / `legacy()`：旧版流程用 `oauth20_token.srf` 轮询与刷新，mock 端点仍走 v2；
  - `device_login_url()` → `https://www.microsoft.com/link?otc=<code>&client_id=<CLIENT_ID>`。
- `crates/horizon-client/src/ha_launcher/platform.rs`：`open_login_url` 白名单允许 `otc` + `client_id`。
- `crates/horizon-client/src/ha_launcher/login.rs`、`accounts.rs`：登录链接改用 `device_login_url()`。

## 7. 字体

`crates/horizon-theme/fonts/Geist-{Regular,Medium,SemiBold}.ttf` 与 `GeistMono-Regular.ttf`
被替换为 **Noto Sans SC 合并 Geist 字重** 的字体（体积各约 13 MB）。

字体不在本仓库里（体积与 SIL OFL 授权），Release 的 APK 已内置；自建方法见 README。
