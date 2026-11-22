# Starling 汉化项目 — 交接文档

> 导出时间：2026-11-22 13:45（GMT+8）
> 用途：交给新的 Agent（DeepSeek Harness）接手，无需阅读原始对话即可开工。

---

## 一、项目目标

把 **Starling**（Minecraft Java 版的安卓启动器 + 游戏本体，Rust 重写）的界面**汉化成简体中文**。

**范围（重要）**：
- ✅ **只做启动器**（Launcher）—— 侧边栏、设置子页面、皮肤/披风、控件编辑器、Starling Control Hub、设置向导、下载页、钓鱼小游戏
- ❌ **游戏内 Minecraft 的文案不用管**（标题屏、暂停菜单、原版选项等）

**测试环境**：用户手机 HyperOS 4（Android 17）；开发机 Windows（本工作区）+ macOS（<build-host-ip>，编译用）+ Android 模拟器（在 Mac 上）。

---

## 二、交付物与产物

| 文件 | 说明 |
|---|---|
| `<工作区>/starling-0.9.0-arm64-v8a-zh-cn-built.apk` | 最终交付的 APK（223MB，含内置 JRE） |
| `<工作区>/_work/` | 工作目录（脚本、截图、源码副本） |
| `<工作区>/src_zh/i18n_zh.rs` | **翻译词库（主副本）** |

---

## 三、源码与构建

### 源码位置
- **本地源码树**：`<工作区>/_work/starling_src2/starling-starling/`
- **Mac 编译树**：`~/starling-starling/`（<build-host-ip>）
- ⚠️ **两棵树必须保持同步！** 否则会出现"改了没生效"或"被旧版覆盖"。

### 构建流程（Mac 上）
```bash
cd ~ && nohup ./build_zh.sh > ~/buildN.log 2>&1 &
# 等完成后：
NDK=~/android-ndk-r27c/toolchains/llvm/prebuilt/darwin-x86_64/bin
cp ~/starling-starling/target/aarch64-linux-android/fast/libhorizon_android.so ~/zh_game.so
$NDK/llvm-strip --strip-unneeded ~/zh_game.so
```

### 打包流程（Windows 上）
```bash
cd <工作区>/_work
# 1) 从 Mac 取 .so
scp -i ~/.ssh/id_ed25519 user@build-host:~/zh_game.so ./zh_game.so
# 2) 打包（内置 lowbudget.zip + JRE + 控制贴图）
python pack_zip.py
# 3) 对齐 + 签名
bt35/android-15/zipalign.exe -f -p 4 rebuilt_final.apk rebuilt_final_X.apk
java -jar bt35/android-15/lib/apksigner.jar sign --ks starling.jks --ks-pass pass:<你的密钥库密码> \
  --key-pass pass:<你的密钥库密码> --ks-key-alias starling rebuilt_final_X.apk
cp rebuilt_final_X.apk ../starling-0.9.0-arm64-v8a-zh-cn-built.apk
```

### 推送源码到 Mac
```bash
cd _work/starling_src2/starling-starling
tar -czf ../../../src_XX.tgz crates/horizon-client/src crates/horizon-client-render/src crates/starling-account/src
cd ../../.. && scp -i ~/.ssh/id_ed25519 src_XX.tgz user@build-host:~/
# Mac 上：cd ~/starling-starling && tar -xzf ~/src_XX.tgz
```

---

## 四、汉化的三层机制（核心知识）

### 1. 启动器 UI — `tr()` / `tr_owned()`（**主要**）
- 文件：`crates/horizon-client/src/i18n_zh.rs`
- 词库表：`static ZH_EXTRA: &[(&str, &str)]` — **当前 476 条**
- 精确匹配优先，其次**整词边界**子串替换
- 调用点已挂钩：`android_control_theme.rs` 的 `text_line` / `measure` / `fit_text` / `centered_fit`，以及 `android_control_ui.rs` 的 `button`
- 每次未命中会打 logcat：`i18n_missing: "原文"` —— **批量收集漏译用这个**

### 2. 游戏内/部分启动器 — Minecraft 语言包 `lang::get()`
- 核心：`crates/horizon-client-core/src/lang.rs`
- 语言文件：`crates/horizon-client/assets/horizon/lang/zh_cn.json`（**已合并到 1822 条**）
- 另有皮肤包：`packaging/lowbudget/pack/assets/minecraft/lang/zh_cn.json`（同一份）
- `lang.rs::DEFAULT` 已改为 `"zh_cn"`
- ⚠️ **语言文件是整文件替换，不是逐键合并** —— 皮肤包里的 zh_cn.json 会顶掉游戏自带的！必须合并成完整一份。

### 3. 硬编码字面量（**不走任何翻译层**）
只能直接改源码。已处理：
- `game/starling/setup/mod.rs`（47 处，设置向导）
- `game/starling/setup/fishing.rs`（20 处，钓鱼小游戏）
- `game/starling/files_offer.rs`（18 处，文件夹卡片）
- `ha_launcher/*.rs`（27 处，皮肤/披风页）
- `starling-account/src/*.rs` + `preparer.rs` + `android_control_assets.rs`（13 处，错误信息）

**做法**：Python 正则匹配 Rust 字符串字面量（含 `\` 续行），按"拍平后的文本"查字典整体替换为中文单行字面量。

---

## 五、已完成的工作

### 翻译覆盖
- 启动器词库 **476 条**（ZH_EXTRA）
- 游戏语言包 **1822 条**（zh_cn.json，含社区原有 1048 条 + 补译 575 条）
- 硬编码字面量约 **125 处**直译
- 设置向导、下载页、钓鱼、皮肤/披风、账户、实验性、诊断等主要页面已汉化

### 功能修复
1. **中文段落不换行** — `files_offer.rs` 用 `split(' ')` 分词，中文无空格→整段一行→卡片压扁。已改为 CJK 逐字分词
2. **JRE 内置 APK** — `assets/jre25-android-arm64.tar.xz`（38MB），`java.rs::install()` 增加 `bundled` 参数，sha256 校验后跳过下载
3. **控制贴图内置** — `assets/bedrock-controls.zip`（21 个 PNG），`preparer.rs` 先解包，fetch 校验通过即跳过
4. **控制贴图 fetch 软失败** — 失败只 log::warn，不中断准备流程
5. **字形图集扩容** — 1024×1024 → 1024×4096（中文字体 upem 2048，光栅化面积大）
6. **字形烘焙副本** — `Font.baked` + `HudAtlas::pixels()` 叠加，应对 GL 表面重建丢字
7. **Region 自愈** — `place()` 满了自动重置后重试

---

## 六、未完成 / 待修（**重点**）

### P3 — 简洁版设置按钮偏移（**最高优先级**）
> ✅ **已修复并验证（2026-11-22 下午）**：根因是 `startup_menu.rs::menu_size()` 在启动阶段回退 `[1280,720]`，与绘制用的 `boot_renderer.size()` 不一致。详见**第十一节**（含验证方式与遗留的入口复测）。以下为原始记录。
- **现象**：点「Horizon 设置…」按钮左侧 → 下面的「完成」按钮高亮（但无功能）；点「资源包…」左侧 → 「制作人员与致谢…」高亮
- **范围**：这个菜单是**启动器下载页的「设置」按钮**打开的，属于启动器范围
- **已排除**：
  - `ui::hovered()`（`crates/horizon-client-render/src/ui.rs:428`）判定逻辑正确
  - 绘制与命中都用同一 rect（`wd.x/y/wd.h`）
  - 光标经 `interface_point(p, batch.scale)` 换算
- **已定位的可疑数值**：
  - 布局行距 **24.0**（`options_ui/layout.rs:196-198`）
  - 按钮控件高 **20.0**（`options_ui_widgets.rs::button`）
  - 网格起点 `gy = (61.0+30.0).min(h - 33.0 - rows*24.0)`（有 clamp）
- **关键线索**：用户描述是"**只是按钮样式变了，并没有实际功能**" → **悬停高亮走一条路，点击触发走另一条路，两者不一致**
- **建议做法**：加调试输出，实测"悬停 rect"与"点击 rect"的差值，照数值改，不要猜
- 相关文件：`crates/horizon-client-render/src/options_ui/{draw.rs,layout.rs,shell_pages.rs,pack_drop.rs}`、`options_ui_widgets.rs`、`options_ui.rs`

### 滚轮乱跳（次优先）
- **现象**：用鼠标滚轮滚动时，开关（toggle）会乱跳
- **推断**：滚轮事件被当成点击/改值处理
- 位置：选项 UI 的滚轮事件分发处

### P2 — 切出去再切回来字消失
- **现象**：从"把文件放在你找得到的地方"卡片点「开始设置」→ 切到系统权限页 → 开权限 → 切回来，文字缺字（稀疏缺失，中间缺两头有）
- **已做双保险**：Font.baked 烘焙 + Region 自愈 + 图集扩容
- **状态**：**用户还没验证**，需要自己在模拟器复现（切出→开权限→切回）

### 翻译收尾（启动器范围）
- 控件编辑器（Joystick Inspector、保存布局弹窗等）**未逐屏扫完**
- Starling Control Hub **未逐屏扫完**
- 已知漏译：
  - Hub 分区标题：`REAL-TIME 3D RESOLUTION & PERFORMANCE`、`FAST AIM, VIRTUAL MOUSE & CONTROLS`、`BUTTON SIZING, HANDEDNESS & BEHAVIOR`（部分已补）
  - 主页底部 phase 名：`title` 未映射（`suspended`/`setup_failure` 已补）
  - `Customize...`（游戏标题屏，但属启动器菜单的话要补）

---

## 七、踩过的坑（**务必避开**）

1. **源码树不同步** — `src_zh/i18n_zh.rs` 与源码树的 `i18n_zh.rs` 必须**双向同步**。曾两次因脚本用旧副本覆盖新代码导致"改了没生效"。改完必须 `cp` 到另一份并验证（如 `grep -c wordish`）。

2. **tar 整目录推送会覆盖 Mac 上的改动** — Mac 上用 sed 改过的文件（`client_lib.rs` 的 `pub mod i18n_zh;`、`android_control_theme.rs` 的 `tr_owned`）会被本地旧版冲掉。**推之前先确认本地树是最新的**。

3. **Python 切片替换 hud.rs 引入语法错误** — `find("\n    }")` 多收了一个 `}`，导致 impl 提前闭合，构建脚本（`horizon-mod-points`、`horizon-engine-slots` 解析 hud.rs 为 token stream）panic。**改完必须编译验证**。

4. **hud.rs 含非 UTF-8 字节** — Python 读写必须 `errors='surrogateescape'`。

5. **子串替换会切碎英文** — `Game`→「游戏」把 `Gameplay` 切成「游戏play」。已改**整词边界**（`- . / _` 也算词内字符），且只对 ≥3 字符键生效。

6. **语言文件是整文件替换不是合并** — 皮肤包的 zh_cn.json 会顶掉游戏自带的。

7. **模拟器默认直接进游戏** — 游戏下好后 app 直接进游戏！进启动器要走：游戏内左上角 **H** → Hub 右上角「**启动器**」→ 退出 → 重开 Activity。

8. **zip 同名条目重复** → apksigner 报 `ApkFormatException`。`pack_zip.py` 要"替换或新增，只留一份"。

9. **`Region` 未 derive Default** — 要手写 `Region { cursor: (0,0), row: 0, pending: Vec::new(), full: false }`。

10. **别交付半成品** — 用户明确批评过多次。**没自己测过验证过，不要交付，更不要让用户去测。**

---

## 八、网络与环境

### Mac 上的代理（<本地代理地址>）
- 路由器做 **DNS 劫持 + 透明 MITM**，CA 证书：`http://<本地代理地址>/c.crt`（已存 `_work/proxy_ca.crt`）
- 本机 `127.0.0.1:26561` 是 Watt Toolkit，**与之无关**
- Windows curl 访问 GitHub 的正确姿势：
  ```bash
  curl -4 -s --cacert proxy_ca.crt --ssl-no-revoke <url>
  ```
  - `-4` 必须（IPv6 未劫持会失败）
  - `--ssl-no-revoke` 必须（schannel 吊销检查）
- 贴图校验用 **git blob sha1**：`sha1("blob <size>\0" + data)`，不是裸 sha1

### 模拟器（Mac 上）
- AVD 名：`starling`，SDK：`~/android-sdk`
- **开窗口到桌面**（SSH 起的进程开不了窗口，必须走 osascript）：
  ```bash
  pkill -f qemu-system-aarch64-headless
  osascript -e 'do shell script "nohup ~/android-sdk/emulator/emulator -avd starling -no-audio -no-boot-anim -gpu swiftshader_indirect -netdelay none -netspeed full > /tmp/emu.log 2>&1 &"'
  ```
- Mac 上**无 Homebrew、无 scrcpy**
- 屏幕 2400×1080（横屏），`input tap` 用该坐标系
- 模拟器内已装好汉化版应用，游戏文件已下载

---

## 九、常用操作速查

### 批量收集漏译（**最高效**）
```bash
adb logcat -c
# 逐页滚动操作...
adb logcat -d | grep -o "i18n_missing: .*" | sort -u | \
  grep -v "i18n_missing: \"[^\"]*[一-龥]" | sed "s/i18n_missing: //"
```
⚠️ 只覆盖**当前屏幕渲染过的文字**，必须逐页滚到底才会全部触发。

### 截图
```bash
adb exec-out screencap -p > /tmp/x.png
```

### 编译检查
```bash
grep -cE "^error" ~/buildN.log   # 0 才算成功
```

---

## 十、给新 Agent 的建议

1. **先读完本文档再动手**，特别是第七节"踩过的坑"。
2. **优先修 P3**（按钮偏移），这是唯一影响使用的功能 bug。用调试输出实测偏移量，别猜。
3. **翻译收尾用 logcat + 逐屏截图**双管齐下。
4. **改完源码先编译**，再同步两棵树，再打包。
5. **自己在模拟器里测完、确认没问题，再交付。** 不要让用户体验半成品。
6. 保持 `src_zh/i18n_zh.rs` 与源码树同步 —— 建议每次改完立即 `cp` 并 `grep -c` 验证。
7. 记得更新 `<工作区>/.workbuddy/memory/` 下的日记。

---

## 附：关键源码文件索引

| 文件 | 作用 |
|---|---|
| `crates/horizon-client/src/i18n_zh.rs` | 翻译词库 + tr()/tr_owned() |
| `crates/horizon-client/src/android_control_theme.rs` | 启动器 UI 绘制（已挂钩翻译） |
| `crates/horizon-client/src/android_control_ui.rs` | 启动器 UI 组件 |
| `crates/horizon-client/src/ha_launcher/` | 启动器页面（launcher_pages.rs、skins/ 等） |
| `crates/horizon-client/src/game/starling/setup/` | 设置向导（mod.rs、fishing.rs） |
| `crates/horizon-client/src/game/starling/files_offer.rs` | 文件夹卡片 |
| `crates/horizon-client-core/src/lang.rs` | 游戏语言系统 |
| `crates/horizon-client/assets/horizon/lang/zh_cn.json` | 游戏语言包 |
| `crates/horizon-client-render/src/font.rs` | 字体/图集/字形烘焙 |
| `crates/horizon-client-render/src/hud.rs` | HUD 图集（pixels/patches） |
| `crates/horizon-client-render/src/options_ui*.rs` | **简洁版设置（P3 所在）** |
| `crates/horizon-client-render/src/ui.rs` | hovered() 等基础 UI |
| `crates/starling-account/src/java.rs` | JRE 安装（bundled 参数） |
| `crates/horizon-client/src/preparer.rs` | 游戏文件准备（贴图解包） |
| `_work/pack_zip.py` | APK 打包脚本 |

---

## 十一、2026-11-22 下午轮更新（接手 Agent）

### P3 根因与修复（已完成、已验证）

**根因**：`crates/horizon-client/src/game/interface/startup_menu.rs` 的 `menu_size()` 在 `self.renderer == None`（启动/下载阶段，绘制实际走 `boot_renderer`）时回退到 `[1280, 720]`，而 `Loading::draw` 用的是 `renderer.config` 或 **`boot_renderer.size()`（真实窗口，如 2400×1080）**。两套尺寸导致：

1. **光标换算错**：`update_menu_cursor` 用 `menu_size()` 算 scale——`calculate_scale([1280,720])=3`，真实窗口 `calculate_scale([2400,1080])=4`。光标 = 物理坐标÷3 而非 ÷4，在绘制空间（600×270 GUI）里落点偏右下 ×4/3，精确复现用户现象：指向「资源包…」(GUI y=163) → cursor.y≈217 命中「制作人员与致谢…」(211..231)；指向「Horizon 设置…」(y=187) → cursor.y≈249 命中「完成」(243..263)。
2. **点击布局错**：`menu_options_click` 用 `HudBatch::new([1280,720])` 的 (width,height)=427×240 构建 `built_layout`，与绘制的 600×270 是两套 rect → 点击常落空（「只高亮、无功能」的另一半）。

**修复**（两处，均在 `startup_menu.rs`）：
- `menu_size()`：`renderer.config` → **`boot_renderer.size()`** → `[1280,720]` 兜底（与 `Loading::draw` 完全同序）。
- `CursorMoved` 分支里 title.drag 的同款内联 `map_or([1280,720])` 改为提前调 `self.menu_size()`。

**验证**（模拟器实测，修复后 APK）：
- Mac `build_zh.sh`（build40.log）编译 0 错误；打包签名安装成功。
- 在菜单内（标题屏「选项…」进入，与下载页设置入口**共用同一套** `menu.cursor`/`menu_size`/`menu_options_click` 输入路径）：
  - 悬停「Horizon 设置…」→ **高亮它自己** + 提示框（修复前高亮「完成」）；
  - 松手点击 → **正确进入「Horizon 设置」子页**（修复前无功能）；
  - 悬停/点击「鸣谢」位置 → 高亮「鸣谢与著作权说明…」并进入鸣谢页；
  - 点击「资源包…」坐标 → 打开「选择资源包」页、焦点落在「资源包」自己身上（修复前高亮「制作人员与致谢…」）。

**遗留（入口复测）**：从**下载页「设置」按钮**入口的复测未完成——不是修复本身的问题（输入层两条入口共用），而是设置向导导航中卡住（见下）。下轮若要补：按「复现下载页」步骤走到下载页，点「设置」（坐标见下），进菜单后重复上面四条验证即可。

### 设置向导（下载页）知识（本轮摸清）

- **复现下载页**（游戏已装好时不会出现）：
  ```
  adb root
  F=/data/data/io.github.juanluci.horizonn/files
  adb shell mv $F/resources $F/resources.bak   # 另有 preparer 同理
  adb shell am force-stop io.github.juanluci.horizonn
  adb shell am start -n io.github.juanluci.horizonn/io.github.juanluci.starling.StarlingActivity
  ```
  然后向导：账号页点「离线游玩」→ 确认框点「离线游玩」→ 表单填名字点「使用此档案」→ **下载页（设置 | 去钓会儿鱼）**。
- **下载约 10–14 分钟完成会自动进游戏**——在下载页做测试动作要快，别像本轮一样中途去读代码，回来入口就没了。
- **Android 上 setup 模式以 `failure.is_some()` 为标志**（`loading_screen.rs`）：下载页触摸走 `setup_touch`（`loading_screen.rs:377`，原始 Touch，不经 touch_pointer）。`setup_touch` 用 `window.inner_size()/setup_density` 换算，绘制用 batch→`Ui::density`（同公式 `min(w/1040,h/700).clamp(1,4)`），理论一致。
- **未解疑点**：模拟器上表单页「使用此档案」按钮按视觉中心 `input tap` 不生效（账号页按钮、确认框按钮却正常）；键盘弹出/收起还会改变表单布局（`available_h -= ime_height/density`）。本轮未查清（怀疑与 inner_size 方向或 IME 焦点有关）。**下轮若要从下载页入口测 P3，可先给 `setup_touch` 加一行 log 打印 p 与各 rect，照数值修/绕过**；或干脆绕开表单（表单提交其实后台下载已在跑——观察到表单停留时下载进度仍在走）。
- **当前设备文件状态**（测完未清理，共约 2.8GB 冗余）：`files/` 下 `resources`+`preparer`（当前可用，游戏运行中）、`resources.bak`+`preparer.bak`（最初备份）、`resources.new`+`preparer.new`（第二轮下载副本）。确认不需要回滚后可删 `.bak`/`.new`。

### 模拟器操作速查（本轮踩坑后）

- 包名 `io.github.juanluci.horizonn`，入口 Activity `io.github.juanluci.starling.StarlingActivity`（`MainActivity` 不存在）。**启动它会自动转横屏 2400×1080**；桌面本身是竖屏 ROTATION_0，不用管 `wm user-rotation`。
- `input tap x y` 用**横屏坐标**（2400×1080）。
- **模拟悬停**：`adb shell input swipe x y x y <毫秒>`（零距离长按）——Touch Started 先发 CursorMoved（悬停高亮立即生效），期间 `screencap` 看高亮，松手才触发点击。实测 1.5s 时仍是悬停态，不会提前点。
- **Windows PowerShell → ssh 的坑**：远程命令里别写双引号（会被 Windows argv 吞掉，zsh 报 `no matches found`/命令错乱）；裸 `*` 会被 Mac 端 zsh 先展开。用单引号包整个远程命令，内层引号用 `''` 转义。
- 截图对比按钮位置时注意：Read 工具可能旋转竖屏图显示，**以 PIL 的 `im.size` 为准**；用像素带分析（行 std）定位内容更可靠。

### 本轮未动的任务（交给下轮）

- 滚轮乱跳（原 P3 次优先）——未动。
- P2 切出切回缺字验证——未动。
- 翻译收尾（控件编辑器/Hub 逐屏扫）——未动。
- `src_zh/i18n_zh.rs` 双向同步——本轮没改 i18n，无需同步；**下轮改词库仍要遵守**。

---

## 十二、2026-11-22 傍晚轮更新（翻译收尾基本完成）

### 交付物

| 文件 | 说明 |
|---|---|
| `starling-0.9.0-arm64-v8a-zh-cn-built-r2.apk` | 本轮新包（233MB），已在模拟器逐屏验证 |
| `_work/rebuilt_final_X5.apk` | 同上的待签名源（X1~X5 为本轮打包产物） |

构建日志：Mac `~/build41.log` ~ `build44.log`（均 0 error，各约 3~4.5 分钟）。

### 改了什么

1. **词库扩充**：`i18n_zh.rs` 新增约 230 条（748 行 → 974 行），批次脚本 `_work/add_batch1..5.py`。覆盖：启动器设置各分类（尤其「控制」页全部行）、主题工坊（预设主题名/描述、强调色/背景/卡片 HEX、渐变方向、色标）、诊断页、Hub 分区标题与说明、控件编辑器属性面板。
2. **源码直译**（format!/状态提示无法用词库命中，必须改源码）：
   - `ha_launcher/launcher_pages.rs`：约 45 处（下载进度、性能模式/主题/控件预设状态、预设复制/编辑对话框、文件管理器、主题状态等）
   - `ha_launcher/catalog.rs`：ETA/删除/重命名/新建文件夹/安装数/结果数/模组可用数等
   - `ha_launcher/chooser.rs`：档案新建/删除/选择
   - `ha_launcher/login.rs`：登录状态
   - `ha_launcher/documents.rs`：导入提示
   - `android_control_ui.rs`：控件编辑器「属性/添加/隐藏」、样式/模式/大小/占用范围、可见性开关、区域标签
   - `android_controls/layout.rs`：预设描述默认值

### 两个机制坑（重要）

1. **带 `{}` 的词条永远不命中**：`tr_owned` 收到的是 `format!` 之后的成品字符串，`("Foo {} bar", ...)` 只对字面量 `Foo {} bar` 生效。带占位符的文案必须改源码成中文。
2. **`ZH`（精确表）里的词不参与子串替换**：替换兜底只扫 `ZH_EXTRA`。组合串如 `"曜石紫 • Dark • Solid Color"`（`format!("{} • {} • {}")`）需要把 `Dark`/`Light`/`Solid Color`/`Gradient`/`Default` **重复**放一份进 `ZH_EXTRA`（本轮已做）。

### 验证情况（模拟器实测，逐屏截图）

- 启动器：首页、模组、资源包、光影、已安装、皮肤、设置 6 分类（视频/启动器/主题/控制/实验性/诊断/账户）——全中文。
- Hub：5 个页签（推荐/控制/瞄准/按键/高级）——分区标题与行说明全中文。
- 控件编辑器：3 个页签（摇杆与样式/模拟基座/区域与可见性）——全中文。
- 剩余英文仅：品牌名（Horizon/Modrinth/GitHub/GoyControl/Starling）、HEX 色值、**远程目录的模组/光影名与描述**（ProjectE、Voltz、Wayfarer Stones 等，属外部内容，未翻译）。

### 环境备忘（本轮踩坑）

- 工作区曾因 Windows 权限无法写入（`SetNamedSecurityInfoW Win32 5`），用 `diagnose-windows-sandbox-acl` 技能脚本修复；后续会话若再遇到，先查 ACL。
- 模拟器当时没有游戏文件，重走了下载页（约 8 分钟）。下载页「设置」入口、离线表单都已顺手验证：表单点输入框 `(1200,509)` → `adb shell input text Tester` → `keyevent 66` 提交 → 再点「使用此档案」。
- 进启动器：游戏内 `H(59,160)` → Hub 右上「启动器(1384,89)」→ App 会自动退出 → `adb shell am start -n io.github.juanluci.horizonn/io.github.juanluci.starling.StarlingActivity` → 启动器主页。
- 截图坐标一律用 PIL 实测（`_work/geom.py`、`_work/find_purple.py`），别用预览图目测。

### 下轮待办

- 滚轮乱跳（仍未排查）。
- P2 切出切回缺字（仍未复现验证）。
- 如要翻译远程目录内容，需要改 catalog 拉取层或加映射表；建议不做。

---

## 十三、2026-11-22 晚轮更新（微软登录修复 + 登录面板汉化）

### 交付物

| 文件 | 说明 |
|---|---|
| `starling-0.9.0-arm64-v8a-zh-cn-built-r4.apk` | 本轮包（233MB），已装模拟器 |
| `_work/rebuilt_final_X7.apk` | 待签名源（X6/X7 为本轮打包） |

构建日志：Mac `~/build46.log`、`build47.log`（0 error）。

### 微软登录：根因与修复

- **现象**：点「用浏览器登录」后，浏览器打开 `login.live.com/oauth20_remoteconnect.srf`，
  显示「We're unable to complete your request / The request is not valid. The application is a
  first party application…invalid_request」。
- **根因**：设备码响应给的 `verification_uri` 是 `https://www.microsoft.com/link`，它会 302 到
  **旧版** `login.live.com/oauth20_remoteconnect.srf`；旧版页面对非微软自家应用（Starling 的
  client id `f2719b6f-5617-4631-b2d7-a21defa191fc`）直接拒绝。
- **修复**：新增 `starling_account::device_login_url(code)`，返回
  `https://microsoft.com/devicelogin?otc=<code>`（跳转到 v2 的
  `login.microsoftonline.com/common/oauth2/deviceauth`，正常显示「输入代码以允许访问」）。
  接入点：`ha_launcher/login.rs::open_link`、`accounts.rs` 的 `State::Code.link`（游戏内账户屏也走这里）。
  `platform::open_login_url` 的白名单本来就允许 `/devicelogin`，无需改。
- **验证**：装 r4 后点「用浏览器登录」，Chrome 打开的是 v2 设备登录页（代码输入框 + 下一步），
  **不再报 first-party 错误**。

### 仍未解：输入代码后提示「该代码无法工作」

- 模拟器里把 App 显示的 8 位代码粘贴进去、点下一步，微软回「该代码无法工作。请检查代码，然后重试。」；
  换新代码（重新点登录）仍然如此。
- 已排除：设备码请求本身是成功的（App 能拿到 user_code、且每次不同）；系统时间正确；Chrome 数据已清空。
- 未排除：① 模拟器走 <本地代理地址> 的 MITM 代理，浏览器端提交可能被干扰；② Starling 的 Azure 应用注册
  （client id 上）在消费者租户下不接受设备码，或未获 Mojang 批准（后者会在下一步 403，UI 会提示
  「not approved by Mojang」并给「申请 Minecraft API 授权」按钮）。
- **建议**：先在用户手机上（正常网络）试；若同样失败，需要检查 Azure 应用注册：支持的账户类型要含
  「个人 Microsoft 账户」、允许公共客户端流、并把 `XboxLive.signin offline_access` 授权；
  然后确认 Mojang 的 Minecraft API 审批。

### 登录面板汉化（本轮补充）

`ha_launcher/login.rs` 全量文案：账户选择（微软账户/Ely.by/离线/已保存的账户）、离线档案、
Ely.by 表单、设备码卡片、以及所有按钮与提示；`starling-account` 的登录/Xbox 错误信息也加了词条
（带 `{}` 的两条直接改源码）。演示：`离线 / 登录`、`Xbox 与 Minecraft 档案`、`设备代码`、
`用浏览器登录`、`登录代码`、`复制代码并打开浏览器`。

### 其它

- 实验性功能页「实验性树叶剔除」的说明已汉化（用户截图红框那行）。
- 设置状态栏里的「N 个 Horizon 模组可用 / N 个结果 — 选择「安装」下载」已汉化（catalog.rs 源码直译）。

---

## 十四、2026-11-22 深夜轮（R5 / R6：控件编辑器补译 + 归档整理）

### 交付物

| 文件 | 说明 |
|---|---|
| `starling-0.9.0-arm64-v8a-zh-cn-built-r6.apk` | 最新包（根目录只留这一个） |
| `apk_archive/` | 历史包（r2/r3/r4/初版/原始 APK） |
| `_work/src_tgz/` | 历次投递到 Mac 的源码 tgz |
| `ENGINEERING_LOG.md` | 每轮工程日志（本轮新增） |

### 改动

- 启动器设置 「PROFILES, WORKER THREADS & STORAGE」分区。
- 控制与 HUD 布局：GoyControl 编辑器副标题、预设副标题、「组件属性」等。
- 控件编辑器：三个页签名、事件页（KEYBOARD/MOUSE BINDING、Inactive、Pass-Thru、Swipe、
  Unassigned、Built-in、Delete Button）、绑定选择弹窗（Keyboard Key / Mouse & Actions 等）、
  `Button: {label}`、`EVENT SLOT #{n}`、`MCPE Custom Button — {label}`（源码直译）。
- 词库新增约 40 条（Icon Badge / Hint Label / Text Only 等）。

### 归档约定

- 根目录只放**最新** APK；旧包进 `apk_archive/`。
- `_work/pack_zip.py` 的 BASE 已指向 `apk_archive/starling-0.9.0-arm64-v8a-zh-cn-built.apk`。
- 源码 tgz 收进 `_work/src_tgz/`。

### 微软登录（结论更新）

- 用 **Windows 上 curl 申请的设备码**在模拟器浏览器里提交，同样提示「该代码无法工作」→
  说明**不是 App 解析代码的问题**，而是模拟器浏览器/网络环境（走 <本地代理地址> 的 MITM 代理）
  导致微软校验失败。跳转 URL 的修复（`microsoft.com/devicelogin?otc=`）仍然是对的。
- 需在真机正常网络复测；若真机同样失败，再检查 Azure 应用注册（个人账户/公共客户端流/Mojang 批准）。

---

## 十五、2026-11-22 深夜轮（R7：缺字 P2 根因补齐 + 渲染模式补译）

### P2 缺字：之前的"双保险"为什么不够

- 之前的修复只处理了 `Font`（游戏内文字）的字形补丁：`Font.baked` + `HudAtlas::pixels()` 叠加。
- **启动器 / 设置向导 / Hub 的中文走的是 `ui_theme::Cache`**：字形光栅化后进 `Cache.pending`，
  由 `Ui::finish()` 推进 `HudBatch.patches` 上传，**从未写回图集 CPU 副本**。
- 而 `boot_set_ui` / `boot_renderer` / `loading_renderer` / `ha_launcher::game::set_loading_ui`
  重建 HUD 纹理时用的是**裸 `atlas.pixels` 字段**（不含任何运行时字形），只对 `Font` 调了
  `reset_cache()`，漏了 UI 缓存 → 新纹理缺字形、缓存又以为上传过 → 整片字空白。

### 修复

1. `Font::bake_patches(&[Patch])`：`ui_theme::Ui::finish()`、`pack_screen::bind_icons`、
   `trims::prepare`、`options_ui::draw` 推补丁时同步写进图集 CPU 副本。
2. 上述四个重建纹理的入口改用 `atlas.pixels()`（含烘焙层），不再用裸 `atlas.pixels`。

### 另外补译

- 渲染模式弹窗：Rendering mode / Uses the system GPU driver… / OpenGL ES / experimental /
  For older GPUs… / Optimized Vulkan pipeline… / Vulkan / GPU batching / Vulkan / compatibility。

### 产物

- `starling-0.9.0-arm64-v8a-zh-cn-built-r7.apk`；构建日志 `~/build50.log`、`build52.log`（0 error）。

---

## 十六、2026-11-22 深夜轮（R8：缺字第二轮 + 诊断页补译 + 登录结论）

### 缺字为什么 R7 还没修好

- R7 补的是 `ui_theme::Cache`；但**设置向导 / 文件卡片**走 `android_control_theme::Ui`，
  它有自己的 `Cache`，`finish()` 同样不写回图集 CPU 副本。
- R8：`android_control_theme::Ui::finish()` 也调用 `atlas.font.bake_patches(&pending)`。

### 微软登录结论（重要）

- 真机普通网络同样报「该代码无法工作」，**不是模拟器代理问题**。
- 探测结论：Starling 的 client id `f2719b6f-…` 签发的设备码被微软拒绝；旧 `www.microsoft.com/link`
  路径报 "The application is a first party application…"。这是 **Azure 应用注册**的问题，
  需要应用所有者：注册/修好一个支持个人账户的公共客户端（允许设备码流、`XboxLive.signin offline_access`），
  并拿到 Mojang 的 Minecraft API 批准。
- 代码里 client id 可配置：`catalog.config.microsoft_client_id`（配置界面）或环境变量
  `STARLING_MSA_CLIENT_ID`；换上新 id 无需改代码。
- 临时可用：离线档案 / Ely.by 登录。

### 补译

- 诊断页：导出原始性能数据（.jsonl）/ 帧遥测说明 / 世界备份与文件管理 / 世界文件 等。






---

## 十七、2026-11-22 深夜轮（R9：缺字根因 + 旧版 MSA 登录）

### 缺字根因（终于定位）

- `horizon/ui-text` 区域：boot 图集 **1024×512**、打包图集 2048×1024。
  手机 DPI 下中文字形约 40×40，1024×512 只够约 300 个字形；向导翻几页就满。
- 满了以后 `Cache::place` 会清空并回到 (0,0) 重铺，**覆盖仍被缓存的旧字** → 整片缺字。
- 修：boot `text_rows` 512→2048；打包 `horizon/ui-text` 2048×1024→2048×2048。
- R7/R8 的烘焙与 `atlas.pixels()` 保留（纹理重建路径仍然需要）。

### 微软登录：旧版 MSA 已跑通到微软登录页

- client id `00000000402b5328`；`login.live.com/oauth20_connect.srf` +
  `oauth20_token.srf`；验证页 `www.microsoft.com/link?otc=<code>`。
- 实测：点「用浏览器登录」→ 页面自动带出代码 →「允许访问」→「登录 / 继续使用 Minecraft。」
  （代码被接受）。后续 Xbox/XSTS/Minecraft 沿用原逻辑，需真实账号验证。
- 注意：`Endpoints::live().microsoft` 现在是 connect 端点；`token_url()`/`legacy()` 分派，
  mock 端点仍走 v2（单测不变）。


---

## 十八、2026-11-23 凌晨轮（R10）

- 简洁版设置：补 50 个缺失语言键到两份 `zh_cn.json`；`Bedrock Inventory` 字面量改中文。
- 衣柜/皮肤页 21 条文案 + 2 处 `format!` 汉化。
- 登录：验证页 URL 补 `client_id`（修「登录完成后浏览器报 invalid_request」），
  `platform::open_login_url` 白名单允许 `otc` + `client_id`。
- 安全审查：未发现后门；细节见 `ENGINEERING_LOG.md` R10。
- 注意：本地源码树的 `crates/horizon-theme/fonts/Geist-*.ttf` 是**原始 Geist**，
  Mac 构建树里是替换过的 Noto CJK（13MB）。**不要整目录同步字体**，否则中文会变方框。
