# multi_pay — AGENTS.md

## Structure

```
multi_pay/
  lib/multi_pay.dart           # Main entry: MultiPay class + barrel exports
  lib/src/
    models/                     # PaymentItem, PaymentResult
    enums/                      # PaymentChannel (alipay/wechat/unionPay)
    builder/                    # PaymentBuilder interface + DefaultPaymentBuilder
    services/                   # PaymentHostApi (MethodChannel), PaymentCallbackHandler (uni_links)
    widget/                     # PaymentItemCard
  pigeon/payment_pigeon.dart    # Pigeon interface definition
  test/multi_pay_test.dart      # Unit tests (14 tests)
  android/...                   # Kotlin: MultiPayPlugin (only impl)
  ios/...                       # Swift: PaymentHostApiImpl, WXApiManager
  ohos/                         # HarmonyOS: MultiPayPlugin.ets + helpers
    patch-hvigor-ohmurl.js      # Runtime Hvigor patch for Alipay bytecode HAR
    setup-ohos-build.sh           # Post-ohpm-install Alipay bytecode HAR patch
  example/lib/main.dart         # Usage example
```

## Commands

- `flutter pub get` — install dependencies
- `flutter analyze` — lint check (must pass: 0 issues)
- `flutter test` — run 14 unit tests (must pass: all green)
- `dart run pigeon ...` — generate platform channel code (run after changing `pigeon/payment_pigeon.dart`)

## Key facts

- **Platform communication**: MethodChannel (`multi_pay_channel`) + uni_links for payment callbacks
- **Pigeon in dev_dependencies**: codegen tool, not runtime dep
- **SDK versions**: Alipay 15.8.40 (Android), WeChat 6.8.34 / 2.0.5 (Android/iOS), UnionPay 3.5.18 / 3.6.3 (Android/iOS)
- **OHOS SDK versions**: Alipay @cashier_alipay/cashiersdk 15.8.43 (bytecode-only HAR), WeChat @tencent/wechat_open_sdk 1.0.17, UnionPay libuppayment.har 3.1.3
- **Init**: `MultiPay.init(alipayAppId:, wechatAppId:, wechatUniversalLink:, alipayScheme:, unionPayScheme:)`
- **Show dialog**: `MultiPay.show(context:, title:, amount:, channels:, customBuilder:, onResult:)`
- **Callback**: listen to `MultiPay.onCallback`
- **UI customization**: Pass `customBuilder` implementing `PaymentBuilder`, or use `DefaultPaymentBuilder(primaryColor:, borderRadius:, ...)`

## Platform requirements

- **Android**: `WXEntryActivity` in `android/.../wxapi/`, `build.gradle.kts` with alipaysdk-android/wechat-sdk-android/upmp deps, `AndroidManifest.xml` with WXEntryActivity/H5PayActivity/UPPayActivity + `<queries>`
- **iOS**: `Podfile` with AlipaySDK/WechatOpenSDK/UPPaymentControl pods, `Info.plist` with URL Schemes + LSApplicationQueriesSchemes, `AppDelegate.swift` routing callbacks
- **OHOS**: 
  1. Ensure `example/ohos/hvigorfile.ts` has `flutterHvigorPlugin` registered (handles `flutter.har` resolution at build time — no local `har/flutter.har` file needed)
  2. `ohpm install` in `example/ohos/`
  3. `source ohos/setup-ohos-build.sh` (patches Alipay bytecode HAR metadata)
  4. `cd example`
  5. `NODE_OPTIONS="--require ${PROJECT_ROOT}/ohos/patch-hvigor-ohmurl.js" fvm flutter build hap --debug`
  6. `node ${PROJECT_ROOT}/ohos/patch-loader-json.js` (injects byteCodeHarInfo into loader.json)

## Gotchas

- `MultiPay.show()` uses `StatefulBuilder` internally — `onSelected` triggers `setState`, UI updates correctly
- `PaymentItemCard` lives in `lib/src/widget/`, separate from `DefaultPaymentBuilder` in `lib/src/builder/`
- All exports in `lib/multi_pay.dart` — import `package:multi_pay/multi_pay.dart` to get all types
- Android plugin impl is `MultiPayPlugin.kt` (single file) — `PaymentHostApiImpl.kt` was removed (duplicate)
- iOS callback routing: `WXApiManager` → `PaymentHostApiImpl`, no `NotificationCenter` dead code
- Tests cover `PaymentChannel`, `PaymentItem`, `PaymentResult` models
- **AGP 9.x**: Both `android/build.gradle.kts` and `example/android/app/build.gradle.kts` need `kotlin("android")` in `plugins { }` block explicitly
- **OHOS `@ohos/flutter_ohos` removed**: All `oh-package.json5` files have `@ohos/flutter_ohos` commented out — `flutterHvigorPlugin` in `hvigorfile.ts` injects it dynamically at build time, pointing to the engine cache. Do NOT restore the local `file:./har/flutter.har` reference.
- **OHOS local Flutter**: project uses `ohos/oh-3.35.7-release` (FVM local), Dart 3.9.2 — switch to `fvm global 3.44.0` for non-OHOS work
