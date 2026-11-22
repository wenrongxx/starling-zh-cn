# 正版（Microsoft 账户）登录：问题与修复思路

这份笔记记录 Starling 中文版修好“微软正版登录”的全过程，供同类启动器参考。
结论先放这里：**换成微软自家的旧版 MSA 设备码流程**，而不是 Azure AD v2 的设备码。

## 1. 症状分类

| 症状 | 真正原因 |
|---|---|
| 申请设备码就 400 / `invalid_client` | client id 或应用注册不可用 |
| 拿到码，浏览器提示「该代码无法工作」 | 验证页不接受这个码：页面不对、协议流不对、或应用没开通设备码 |
| 浏览器登录完成后跳 `invalid_request` | 验证页缺参数（本项目缺的是 `client_id`） |

先做**外部复现**再改代码：

```bash
curl -s -X POST https://login.live.com/oauth20_connect.srf \
  -d "client_id=00000000402b5328&scope=XboxLive.signin%20offline_access&response_type=device_code"
```

拿到 `user_code` 后换一台手机/电脑打开验证页输入。如果同样被拒，就说明问题不在客户端的参数解析。

## 2. 为什么 Azure AD v2 走不通

Starling 原本用 `login.microsoftonline.com/consumers/oauth2/v2.0/devicecode` + 应用自己的 client id：

- 设备码能签发，但验证页一律拒绝 → 该应用注册没有为“个人账户 + 设备码流”配置好；
- 走旧路由 `www.microsoft.com/link` 还会直接报 *“The application is a first party application…”*。

这类问题在客户端侧改参数解决不了，只能换认证通道。

## 3. 可用的旧版 MSA 设备码流程

用微软自家 Minecraft 客户端的公共 client id：`00000000402b5328`。

### 3.1 申请设备码

```
POST https://login.live.com/oauth20_connect.srf
client_id=00000000402b5328
scope=XboxLive.signin offline_access
response_type=device_code
```

返回：

```json
{"user_code":"H2UVR66Q","device_code":"...","verification_uri":"https://www.microsoft.com/link","interval":5,"expires_in":900}
```

### 3.2 打开验证页

```
https://www.microsoft.com/link?otc=<user_code>&client_id=00000000402b5328
```

- 带 `otc`：页面会把代码预先填好，按钮直接是「允许访问」；
- 必须再带 `client_id`，否则点完「允许访问」登录完成后会跳到
  `invalid_request: The provided request must include a 'client_id' input parameter.`

### 3.3 轮询换 token

```
POST https://login.live.com/oauth20_token.srf
client_id=…&device_code=…&grant_type=urn:ietf:params:oauth:grant-type:device_code
```

- 未确认：HTTP 400 + `{"error":"authorization_pending"}` —— 按错误码判断，别当异常放弃；
- 太快：`slow_down` → 轮询间隔 +5 秒；
- 成功：`access_token` + `refresh_token`。

### 3.4 刷新

同一端点，`grant_type=refresh_token&refresh_token=…&client_id=…&scope=XboxLive.signin offline_access`。

## 4. 接 Xbox / Minecraft（与上游一致，不用改）

1. `POST https://user.auth.xboxlive.com/user/authenticate`
   `RpsTicket: "d=<MSA access_token>"`，`SiteName: user.auth.xboxlive.com` → XBL token
2. `POST https://xsts.auth.xboxlive.com/xsts/authorize`
   `RelyingParty: "rp://api.minecraftservices.com/"` → XSTS token
   （注意 `XErr` 错误码：无 Xbox 档案、未成年、地区不支持等都要有专门文案）
3. `POST https://api.minecraftservices.com/authentication/login_with_xbox`
   `identityToken: "XBL3.0 x=<uhs>;<xsts>"`
4. `GET /entitlements/mcstore` —— **正版判定看这里**，别跳过
5. `GET /minecraft/profile` —— UUID、皮肤、披风

## 5. 工程细节

- 端点集中成常量/配置，微软改流程时只改一处；
- 错误码映射成人话：`authorization_pending` 继续等、`slow_down` 加间隔、`expired_token` 重来、`invalid_grant` 清会话；
- 轮询要可取消；网络失败不终止登录，记下最后一次错误；
- refresh token 用系统密钥库封存（Android Keystore），启动时静默刷新；
- **永远不要记录 token / 密码**；密码只在浏览器里输入，App 不接触。

## 6. 边界与风险

- 用微软自家 public client id 是社区启动器的常见做法，但**不是官方授权渠道**，微软随时可能收紧；
  正规做法是自己注册 Azure 公共客户端，并向 Mojang 申请 Minecraft API 访问。
- 这条链路只解决“认证”，正版判定仍然靠 `/entitlements/mcstore`；不要跳过，也不要把离线档案包装成正版。
- 不要把账号密码或别人的 refresh token 内置进客户端。

## 7. 代码位置（本仓库对应的上游文件）

- `crates/starling-account/src/lib.rs`：`CLIENT_ID`、`Endpoints::live()`、`device_code()`、`poll()`、
  `refresh_ms()`、`wait_for_sign_in()`、`device_login_url()`
- `crates/horizon-client/src/ha_launcher/login.rs`、`accounts.rs`：把登录链接交给系统浏览器
- `crates/horizon-client/src/ha_launcher/platform.rs`：`open_login_url` 白名单（host + path + query 校验）
