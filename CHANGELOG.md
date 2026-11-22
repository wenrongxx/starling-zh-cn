# 版本记录

## v0.9.0-zh-cn.3（当前）

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
