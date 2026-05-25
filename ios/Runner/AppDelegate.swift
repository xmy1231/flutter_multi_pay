import Flutter
import UIKit
import AlipaySDK
import UPPaymentControlMini

@main
@objc class AppDelegate: FlutterAppDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        WxPayBridge.setWxDelegate(MultiPayPlugin.shared)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        let urlString = url.absoluteString

        if url.host == "safepay" || urlString.contains("alipays") {
            AlipaySDK.defaultInstance()?.processOrder(withPaymentResult: url) { _ in }
            return true
        }

        if url.scheme?.hasPrefix("wxd") == true {
            return WxPayBridge.handleOpenURL(url)
        }

        if url.scheme?.hasPrefix("uppay") == true || url.scheme?.hasPrefix("uppays") == true {
            UPPaymentControl.defaultControl().handlePaymentResult(url) { code, data in
                MultiPayPlugin.shared.handleUnionPayCallback(code: code, data: data)
            }
            return true
        }

        return false
    }
}