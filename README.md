# multi_pay

Flutter 聚合支付插件，支持支付宝、微信支付、银联云闪付。

**无内置 UI** — 只提供支付能力接口，UI 由开发者自己实现。

## 支持的渠道

| 渠道 | 支付方式 | App 未安装处理 |
|------|---------|---------------|
| 支付宝 | App 支付 → WAP 降级 | 服务端控制，无门槛 |
| 微信支付 | App 支付 | 插件返回 `APP_NOT_INSTALLED` |
| 银联云闪付 | App 支付 → WAP 降级 | 服务端控制，无门槛 |

## SDK 版本

| SDK | Android | iOS | OHOS |
|-----|---------|-----|------|
| 支付宝 | 15.8.40 | 15.8.40 | @cashier_alipay/cashiersdk ^15.8.43 |
| 微信 | 6.8.34 | 2.0.5 | @tencent/wechat_open_sdk ^1.0.17 |
| 银联 | 3.5.18 | 3.6.3 | libuppayment.har 3.1.3 |

## 安装

```yaml
dependencies:
  multi_pay: ^1.0.0
```

## 快速开始

### 1. 初始化

```dart
import 'package:multi_pay/multi_pay.dart';

void main() async {
  await MultiPay.init(
    alipayAppId: 'your_alipay_appid',
    alipayScheme: 'yourAlipayScheme',
    wechatAppId: 'your_wechat_appid',
    wechatUniversalLink: 'https://your-app.com/ulink/',
    unionPayTnMode: '00',  // '00' 生产 / '01' 测试
    unionPayScheme: 'yourUnionPayScheme',
  );
}
```

### 2. 监听支付回调

```dart
MultiPay.onCallback.listen((result) {
  if (result.status == 'success') {
    showSnackBar('支付成功 - ${result.channel.displayName}');
  }
});
```

### 3. 发起支付

```dart
final result = await MultiPay.pay(
  channel: PaymentChannel.alipay,
  orderInfo: '{"app_id":"your_app_id","method":"alipay.trade.app.pay"}',
);

if (result.isSuccess) {
  print('支付成功: ${result.orderId}');
} else if (result.errorCode == 'APP_NOT_INSTALLED') {
  showDialog(context, '请先安装微信客户端');
} else {
  print('支付失败: ${result.errorMessage}');
}
```

## API

| 方法 | 说明 |
|------|------|
| `init(...)` | 初始化 SDK（只需调用一次） |
| `pay(channel, orderInfo)` | 发起支付 |
| `onCallback` | 支付结果回调流 |
| `isAppInstalled(channel)` | 检查支付 App 是否安装 |
| `getAvailableChannels()` | 获取已安装的支付渠道列表 |

### PaymentChannel

- `PaymentChannel.alipay` — 支付宝
- `PaymentChannel.wechat` — 微信支付
- `PaymentChannel.unionPay` — 银联云闪付

扩展方法（`PaymentChannelExtension`）：
- `.name` — 渠道标识字符串（`alipay` / `wechat` / `unionPay`）
- `.displayName` — 中文名称（`支付宝` / `微信支付` / `银联云闪付`）
- `.fromString(name)` — 字符串转枚举

### PaymentResult

| 字段 | 类型 | 说明 |
|------|------|------|
| `channel` | `PaymentChannel` | 支付渠道 |
| `status` | `PaymentStatus` | `success` / `failed` / `cancelled` / `pending` |
| `isSuccess` | `bool` | 快捷判断 |
| `isFailed` | `bool` | 快捷判断 |
| `isCancelled` | `bool` | 快捷判断 |
| `orderId` | `String?` | 订单号 |
| `errorCode` | `String?` | 错误码（微信未安装时返回 `APP_NOT_INSTALLED`） |
| `errorMessage` | `String?` | 错误描述 |

## 错误处理

```dart
final result = await MultiPay.pay(channel: PaymentChannel.wechat, orderInfo: orderInfo);

switch (result.errorCode) {
  case 'APP_NOT_INSTALLED':
    break;
  case 'PAYMENT_ERROR':
    break;
  default:
    if (result.isSuccess) {
      // 支付成功
    } else if (result.isCancelled) {
      // 用户取消
    }
}
```

## 示例

完整示例见 [example/lib/main.dart](example/lib/main.dart)。

## 平台集成指南

> **Android/iOS 开发者无需任何额外配置**：标准 Flutter 会自动忽略插件的 OHOS
> 平台声明，不会报错也不会产生警告。直接 `flutter pub add multi_pay` 即可，
> 以下内容仅在你需要支持 HarmonyOS 时参考。

### Android

插件自动合并以下内容到你的项目（**无需手动配置**）：

- `AndroidManifest.xml`：`INTERNET` / `ACCESS_NETWORK_STATE` 等权限、`com.tencent.mm` / `com.eg.android.AlipayGphone` 等 `<queries>`、三个支付渠道的 Activity 声明
- `WXEntryActivity`：微信支付回调处理（位于 `com.plugin.multipay.wxapi`）

开发者需要做的：

**1. `app/build.gradle.kts` — 添加 SDK 依赖**

```kotlin
plugins {
    id("com.android.application")
    kotlin("android") version "2.3.20"    // 必须！AGP 9.x 需要显式声明
}

android {
    defaultConfig {
        manifestPlaceholders["ALIPAY_APPID"] = "你的支付宝AppID"
    }
}

dependencies {
    implementation("com.alipay.sdk:alipaysdk-android:15.8.40")
    implementation("com.tencent.mm.opensdk:wechat-sdk-android:6.8.34")
}
```

如果你的项目没有 `kotlin("android")`，需要新增。

**2. 修改微信的回调 scheme**

插件的 `AndroidManifest.xml` 中包含：
```xml
<data android:scheme="wxd930ea5d5a258f4" />
```

将 `wxd930ea5d5a258f4` 替换为你的微信 AppID。由于插件声明了 `tools:replace`，你可以在自己的 `AndroidManifest.xml` 中添加 intent-filter 覆盖，或直接接受合并行为。

**3. 银联 SDK**

银联 `.aar` 文件需要手动放入 `app/libs/`，并在 `build.gradle.kts` 中添加：

```kotlin
implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
```

---

### iOS

开发者需要配置 Info.plist、Podfile 和 AppDelegate。

**1. `Info.plist` — URL Schemes 与查询白名单**

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>wxd930ea5d5a258f4</string>  <!-- 你的微信 AppID -->
        </array>
    </dict>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourAlipayScheme</string>
        </array>
    </dict>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourUnionPayScheme</string>
        </array>
    </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>weixin</string>
    <string>wechat</string>
    <string>alipay</string>
    <string>alipays</string>
    <string>uppay</string>
    <string>uppays</string>
    <string>uppaywallet</string>
    <string>uppayx</string>
</array>
```

**2. `Podfile` — 支付 SDK 集成**

```ruby
platform :ios, '13.0'

# 本地 vendored WechatOpenSDK（支持 arm64 模拟器）
pod 'WechatOpenSDK', :path => 'WechatOpenSDK'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end

  # 移除 EXCLUDED_ARCHS 中的 arm64，使 Apple Silicon 模拟器可运行
  # 同时对 WechatOpenSDK 和 AlipaySDK 的 arm64 Mach-O 切片做 LC_VERSION_MIN_IPHONEOS 补丁

  # 详细补丁代码见 example/ios/Podfile
  # 关键操作：
  #   - 修改 Flutter/Generated.xcconfig 和 Pods-Runner xcconfig
  #   - 将 arm64 从 EXCLUDED_ARCHS[sdk=iphonesimulator*] 移除
  #   - 对 libWechatOpenSDK.a 和 AlipaySDK.xcframework 模拟器切片执行 Mach-O 补丁
  #   - 添加 required frameworks 到 OTHER_LDFLAGS
end
```

完整 `Podfile` 参考 [example/ios/Podfile](example/ios/Podfile)。

如需使用 CocoaPods 引入 AlipaySDK：

```ruby
pod 'AlipaySDK'
```

或手动下载 AlipaySDK.xcframework 放入项目。

**3. `AppDelegate.swift` — 支付回调路由**

```swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if WxPayBridge.handleOpen(url) { return true }
    return super.application(app, open: url, options: options)
  }
}
```

---

### OHOS (HarmonyOS)

**前提条件**：需要 FVM 管理的 OHOS Flutter SDK（见下方 FVM 版本管理章节）。

**1. `oh-package.json5` — 插件依赖声明**

根模块（`ohos/oh-package.json5`）：

```json5
{
  dependencies: {
  },
  overrides: {
    multi_pay: "../../ohos",
  },
}
```

entry 模块（`ohos/entry/oh-package.json5`）：

```json5
{
  name: "entry",
  dependencies: {
    multi_pay: "../../../ohos",
  },
}
```

**2. `hvigorfile.ts` — 注册 Flutter 构建插件**

根模块（`ohos/hvigorfile.ts`）：

```typescript
import path from 'path'
import { appTasks } from '@ohos/hvigor-ohos-plugin'
import { flutterHvigorPlugin } from 'flutter-hvigor-plugin'

export default {
    system: appTasks,
    plugins: [flutterHvigorPlugin(path.dirname(__dirname))]
}
```

entry 模块（`ohos/entry/hvigorfile.ts`）：

```typescript
import { hapTasks } from '@ohos/hvigor-ohos-plugin'
export default {
    system: hapTasks,
    plugins: []
}
```

**3. `module.json5` — 应用配置**

```json5
{
  module: {
    name: "entry",
    type: "entry",
    deviceTypes: ["phone"],
    querySchemes: ["alipays", "uppaywallet", "uppaysdk"],
    abilities: [{
      name: "EntryAbility",
      srcEntry: "./ets/entryability/EntryAbility.ets",
      exported: true,
      skills: [{
        entities: ["entity.system.home"],
        actions: ["action.system.home"],
        uris: [{
          scheme: "uppaymerchantdemo",  // 你的银联 URI scheme
        }],
      }],
    }],
    requestPermissions: [{ name: "ohos.permission.INTERNET" }],
  },
}
```

**4. `EntryAbility.ets` — 支付回调路由**

```typescript
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos'
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant'
import Want from '@ohos.app.ability.Want'
import AbilityConstant from '@ohos.app.ability.AbilityConstant'
import { MultiPayPlugin } from 'multi_pay'

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    super.onNewWant(want, launchParam)
    MultiPayPlugin.handleWant(want)
  }
}
```

**5. 安装 OHOS 依赖**

```bash
cd ohos
ohpm install
```

**6. 支付宝字节码 HAR 补丁（必须）**

```bash
source ohos/setup-ohos-build.sh
```

该脚本将支付宝 SDK 的 `oh-package.json5` 缓存文件中注入 `"byteCodeHar": true`，使 Hvigor 识别字节码 HAR。

**7. 构建 HAP**

```bash
cd example

NODE_OPTIONS="--require ${PROJECT_ROOT}/ohos/patch-hvigor-ohmurl.js" \
  fvm flutter build hap --debug

node ${PROJECT_ROOT}/ohos/patch-loader-json.js
```

构建流程说明：
- `patch-hvigor-ohmurl.js`：注入 `strictMode.useNormalizedOHMUrl` 配置，修改 loader.json 使编译器找到支付宝字节码文件
- `patch-loader-json.js`：在 `loader_out/<config>/ets/loader.json` 中注入 `byteCodeHarInfo` 条目

---

## FVM 版本管理

> **FVM 仅用于 OHOS 开发场景**：如果只做 Android/iOS，用标准 Flutter 即可，
> 无需安装 FVM。

`multi_pay` 支持三个平台，但 OHOS 需要独立的 Flutter SDK fork。建议使用 FVM 管理版本切换。

### 版本对应

| 目标平台 | Flutter SDK | 版本 | Dart |
|---------|-------------|------|------|
| Android / iOS | 标准 Flutter（stable） | 最新稳定版 | 最新 |
| OHOS (HarmonyOS) | OpenHarmony-TPC fork | oh-3.35.7-release | 3.9.2 |

### 安装 FVM

```bash
brew install fvm
# 或
dart pub global activate fvm
```

### 安装 SDK 版本

```bash
# 安装标准 Flutter
fvm install 3.44.0

# 安装 OHOS Flutter（需先添加自定义版本源）
fvm install ohos/oh-3.35.7-release
```

### 切换项目版本

```bash
# Android / iOS 开发
cd your_project
fvm use 3.44.0

# OHOS 开发
cd your_project
fvm use ohos/oh-3.35.7-release
```

切换后重启 VSCode 使 Flutter 扩展加载正确的 SDK。

### 快捷别名（可选）

在 `~/.zshrc` 中添加：

```bash
alias f-android='cd ~/your_project && fvm use 3.44.0'
alias f-ohos='cd ~/your_project && fvm use ohos/oh-3.35.7-release'
```

## License

MIT
>>>>>>> a532184 (Initial commit: multi_pay flutter plugin)
