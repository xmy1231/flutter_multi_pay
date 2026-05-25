import Flutter
import UIKit
import AlipaySDK
import UPPaymentControlMini

@objc public class MultiPayPlugin: NSObject, FlutterPlugin {

    static let shared = MultiPayPlugin()

    private var alipayAppId: String?
    private var wechatAppId: String?
    private var wechatUniversalLink: String?
    private var unionPayTnMode: String?
    private var alipayScheme: String = "alipay"
    private var unionPayScheme: String = "uppay"
    private var pendingResult: FlutterResult?
    private var paymentChannel: String = ""
    private var unionPayPendingResult: FlutterResult?

    @objc public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "multi_pay_channel",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(shared, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "pay":
            guard let args = call.arguments as? [String: Any],
                  let channel = args["channel"] as? String,
                  let orderInfo = args["orderInfo"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing required arguments", details: nil))
                return
            }
            handlePay(channel: channel, orderInfo: orderInfo, result: result)

        case "isAppInstalled":
            guard let args = call.arguments as? [String: Any],
                  let channel = args["channel"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing channel", details: nil))
                return
            }
            result(handleIsAppInstalled(channel: channel))

        case "initSdk":
            if let args = call.arguments as? [String: Any] {
                alipayAppId = args["alipayAppId"] as? String
                wechatAppId = args["wechatAppId"] as? String
                wechatUniversalLink = args["wechatUniversalLink"] as? String
                unionPayTnMode = args["unionPayTnMode"] as? String
                alipayScheme = args["alipayScheme"] as? String ?? "alipay"
                unionPayScheme = args["unionPayScheme"] as? String ?? "uppay"

                if let appId = wechatAppId {
                    let universalLink = wechatUniversalLink ?? "https://your-universal-link.com/"
                    WxPayBridge.registerApp(appId, universalLink: universalLink)
                }
            }
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handlePay(channel: String, orderInfo: String, result: @escaping FlutterResult) {
        pendingResult = result
        paymentChannel = channel

        switch channel {
        case "alipay":
            payWithAlipay(orderInfo: orderInfo)
        case "wechat":
            payWithWechat(orderInfo: orderInfo)
        case "unionPay":
            payWithUnionPay(orderInfo: orderInfo)
        default:
            result(FlutterError(code: "UNKNOWN_CHANNEL", message: "Unknown channel: \(channel)", details: nil))
            pendingResult = nil
        }
    }

    private func payWithAlipay(orderInfo: String) {
        guard let topController = UIApplication.shared.topViewController() else {
            pendingResult?(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No view controller", details: nil))
            pendingResult = nil
            return
        }

        AlipaySDK.defaultService().payOrder(orderInfo, fromScheme: alipayScheme) { [weak self] resDict in
            guard let self = self else { return }
            self.didReceiveAlipayResult(resDict)
        }
    }

    private func didReceiveAlipayResult(_ resDict: [AnyHashable: Any]?) {
        let resultStatus = resDict?["resultStatus"] as? String ?? ""
        let status: String

        switch resultStatus {
        case "9000":
            status = "success"
        case "6001":
            status = "cancelled"
        default:
            status = "failed"
        }

        let response: [String: Any] = [
            "channel": "alipay",
            "status": status,
            "result": resDict ?? [:]
        ]

        pendingResult?(response)
        pendingResult = nil
    }

    private func payWithWechat(orderInfo: String) {
        guard wechatAppId != nil else {
            pendingResult?(FlutterError(code: "NOT_CONFIGURED", message: "Wechat AppId not configured", details: nil))
            pendingResult = nil
            return
        }

        guard WxPayBridge.isWxAppInstalled() else {
            pendingResult?(FlutterError(code: "APP_NOT_INSTALLED", message: "Wechat is not installed", details: nil))
            pendingResult = nil
            return
        }

        guard let orderDict = parseOrderInfo(orderInfo) else {
            pendingResult?(FlutterError(code: "INVALID_ORDER", message: "Invalid order info", details: nil))
            pendingResult = nil
            return
        }

        let partnerId = orderDict["partnerId"] as? String ?? ""
        let prepayId = orderDict["prepayId"] as? String ?? ""
        let package = orderDict["package"] as? String ?? "Sign=WXPay"
        let nonceStr = orderDict["nonceStr"] as? String ?? ""
        let timeStamp = UInt32(orderDict["timeStamp"] as? String ?? "") ?? 0
        let sign = orderDict["sign"] as? String ?? ""

        WxPayBridge.sendPayReq(withPartnerId: partnerId, prepayId: prepayId, package: package, nonceStr: nonceStr, timeStamp: timeStamp, sign: sign)

        pendingResult?(["channel": "wechat", "status": "pending"])
        pendingResult = nil
    }

    private func payWithUnionPay(orderInfo: String) {
        guard let topController = UIApplication.shared.topViewController() else {
            pendingResult?(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No view controller", details: nil))
            pendingResult = nil
            return
        }

        let mode = unionPayTnMode ?? "00"
        unionPayPendingResult = pendingResult
        pendingResult = nil

        let started = UPPaymentControl.default().startPay(
            orderInfo,
            fromScheme: unionPayScheme,
            mode: mode,
            viewController: topController
        )
        if !started {
            let result = unionPayPendingResult
            unionPayPendingResult = nil
            result?(FlutterError(code: "UNIONPAY_ERROR", message: "Failed to start UnionPay", details: nil))
        }
    }

    func handleUnionPayCallback(code: String, data: [AnyHashable: Any]?) {
        guard let result = unionPayPendingResult else { return }
        unionPayPendingResult = nil

        let status: String
        switch code {
        case "success":
            status = "success"
        case "cancel":
            status = "cancelled"
        default:
            status = "failed"
        }

        result(["channel": "unionPay", "status": status])
    }

    func didReceiveWechatPayResponse(errCode: Int, errStr: String) {
        let status: String
        switch errCode {
        case 0:
            status = "success"
        case -2:
            status = "cancelled"
        default:
            status = "failed"
        }

        let response: [String: Any] = [
            "channel": "wechat",
            "status": status,
            "errCode": errCode,
            "errStr": errStr
        ]

        pendingResult?(response)
        pendingResult = nil
    }

    private func handleIsAppInstalled(channel: String) -> Bool {
        switch channel {
        case "alipay":
            return UIApplication.shared.canOpenURL(URL(string: "alipay://")!)
        case "wechat":
            return WxPayBridge.isWxAppInstalled()
        case "unionPay":
            let mode = unionPayTnMode ?? "00"
            return UPPaymentControl.default().isPaymentAppInstalled(mode, withMerchantInfo: "")
        default:
            return false
        }
    }

    private func parseOrderInfo(_ jsonString: String) -> [String: Any]? {
        guard let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return dict
    }
}

extension MultiPayPlugin: WxPayDelegate {
    public func onWechatPayResponse(withErrCode errCode: Int32, errStr: String) {
        didReceiveWechatPayResponse(errCode: Int(errCode), errStr: errStr)
    }
}

extension UIApplication {
    func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              var topController = window.rootViewController else {
            return nil
        }

        while let presentedController = topController.presentedViewController {
            topController = presentedController
        }

        return topController
    }
}
