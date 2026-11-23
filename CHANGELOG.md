# 版本记录

## v0.9.0-zh-cn.5（当前）

- 删掉 APK 里一份重复的游戏库（上游的 `libhorizon_mod_host.so`，130.9 MiB）。
  我们的 `libhorizon_android.so` 是静态链接的完整构建，本身已包含全部符号，那份是冗余的。
- 体积 222.8 MiB → **170.1 MiB**，功能不变。

## v0.9.0-zh-cn.4（历史）

## v0.9.0-zh-cn.4（当前）

- 把 **MIT 许可证全文、上游第三方声明、发行合规说明**放进 APK（`assets/licenses/`），
  满足 MIT “随副本分发声明”的要求；功能与 v3 相同。
- 体积 222.8 MiB。

## v0.9.0-zh-cn.3（已下架）

- 保留内置 JRE 并补 JRE 许可证；APK 内当时缺 MIT 许可证，改用 v4。

## 文档更新（2026-11-22）

- `LICENSE` 增列汉化部分版权行（上游 MIT 保留）。
- `README` 增加独立的「许可证」段落：整体 MIT、汉化部分的授权、非 MIT 组件表、非官方声明。
- `NOTICE.md` 增加许可证总览表；把“仅供学习交流”改为明确的授权表述。

## v0.9.0-zh-cn.3（历史）

- **保留内置 Java 运行时**（国内下载太慢），但补齐合规：APK 内 `assets/licenses/` 与仓库
  `third_party/jre25/` 附 GPLv2、Classpath Exception、Additional License Info 以及来源/源码地址。
- 依旧**不打包 Mojang 资源**：基岩版触控按钮贴图由应用首次运行时自行下载。
- 字体许可证（SIL OFL 1.1）随包分发。
- 体积约 222 MB。功能与 r13 相同。

## v0.9.0-zh-cn.2（已下架）

- 合规版：去掉 Mojang 资源与内置 JRE。
- 因内置 JRE 移除后首次启动要下载 36 MB，速度太慢，改用 v3 方案；该版本不再提供下载。

## v0.9.0-zh-cn.1（已下架）

- 第一版：内置 JRE、包含 Mojang 触控贴图，未附任何许可证，合规不达标，已撤回。
