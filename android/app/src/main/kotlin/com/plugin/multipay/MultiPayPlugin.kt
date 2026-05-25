package com.plugin.multipay

import android.app.Activity
import android.content.Context
import android.content.Intent
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.alipay.sdk.app.PayTask
import com.tencent.mm.opensdk.modelpay.PayReq
import com.tencent.mm.opensdk.openapi.IWXAPI
import com.tencent.mm.opensdk.openapi.WXAPIFactory
import com.unionpay.sdk.UPPayActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class MultiPayPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware,
    ActivityPluginBinding.OnActivityResultListener {

    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private var currentActivity: Activity? = null
    private var pendingResult: MethodChannel.Result? = null
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    private var alipayAppId: String? = null
    private var wechatAppId: String? = null
    private var unionPayTnMode: String? = null
    private var isWechatPayPending = false

    companion object {
        private const val UNIONPAY_REQUEST_CODE = 1002
        var wechatAppId: String? = null
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "multi_pay_channel")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pay" -> handlePay(call, result)
            "isAppInstalled" -> handleIsAppInstalled(call, result)
            "initSdk" -> handleInitSdk(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handlePay(call: MethodCall, result: MethodChannel.Result) {
        val channelName = call.argument<String>("channel")
        val orderInfo = call.argument<String>("orderInfo")

        if (channelName == null || orderInfo == null) {
            result.error("INVALID_ARGS", "Channel and orderInfo are required", null)
            return
        }

        pendingResult = result

        when (channelName) {
            "alipay" -> payWithAlipay(orderInfo)
            "wechat" -> payWithWechat(orderInfo)
            "unionPay" -> payWithUnionPay(orderInfo)
            else -> {
                result.error("UNKNOWN_CHANNEL", "Unknown channel: $channelName", null)
                pendingResult = null
            }
        }
    }

    private fun payWithAlipay(orderInfo: String) {
        val activity = currentActivity
        if (activity == null) {
            pendingResult?.error("NO_ACTIVITY", "Activity is not available", null)
            pendingResult = null
            return
        }

        scope.launch {
            try {
                val alipayTask = PayTask(activity)
                val payResult = alipayTask.payV2(orderInfo, true)

                val resultStatus = payResult["resultStatus"] as? String ?: ""
                val resultCode = when (resultStatus) {
                    "9000" -> "success"
                    "6001" -> "cancelled"
                    else -> "failed"
                }

                val response = hashMapOf<String, Any?>(
                    "channel" to "alipay",
                    "status" to resultCode,
                    "result" to payResult
                )

                pendingResult?.success(response)
            } catch (e: Exception) {
                pendingResult?.error("ALIPAY_ERROR", e.message, null)
            } finally {
                pendingResult = null
            }
        }
    }

    private fun payWithWechat(orderInfo: String) {
        val wechatAppId = this.wechatAppId

        if (wechatAppId == null) {
            pendingResult?.error("NOT_CONFIGURED", "Wechat AppId not configured", null)
            pendingResult = null
            return
        }

        val api: IWXAPI = WXAPIFactory.createWXAPI(context, wechatAppId)

        if (!api.isWXAppInstalled) {
            pendingResult?.error("APP_NOT_INSTALLED", "Wechat is not installed", null)
            pendingResult = null
            return
        }

        try {
            val orderMap = parseOrderInfo(orderInfo)
            if (orderMap.isEmpty()) {
                pendingResult?.error("INVALID_ORDER", "Failed to parse order info", null)
                pendingResult = null
                return
            }

            val req = PayReq().apply {
                appId = orderMap["appId"] as? String ?: wechatAppId
                partnerId = orderMap["partnerId"] as? String
                prepayId = orderMap["prepayId"] as? String
                packageValue = orderMap["package"] as? String ?: "Sign=WXPay"
                nonceStr = orderMap["nonceStr"] as? String
                timeStamp = orderMap["timeStamp"] as? String
                sign = orderMap["sign"] as? String
            }

            api.registerApp(wechatAppId)
            val sent = api.sendReq(req)

            if (!sent) {
                pendingResult?.error("SEND_REQ_FAILED", "Failed to send request to Wechat", null)
                pendingResult = null
            } else {
                isWechatPayPending = true
            }
        } catch (e: Exception) {
            pendingResult?.error("WECHAT_ERROR", e.message, null)
            pendingResult = null
        }
    }

    private fun payWithUnionPay(orderInfo: String) {
        val activity = currentActivity
        if (activity == null) {
            pendingResult?.error("NO_ACTIVITY", "Activity is not available", null)
            pendingResult = null
            return
        }

        try {
            val mode = unionPayTnMode ?: "00"
            val intent = Intent(activity, UPPayActivity::class.java).apply {
                putExtra("merchant", orderInfo)
                putExtra("mode", mode)
            }
            activity.startActivityForResult(intent, UNIONPAY_REQUEST_CODE)
        } catch (e: Exception) {
            pendingResult?.error("UNIONPAY_ERROR", e.message, null)
            pendingResult = null
        }
    }

    private fun handleIsAppInstalled(call: MethodCall, result: MethodChannel.Result) {
        val channelName = call.argument<String>("channel")
        if (channelName == null) {
            result.error("INVALID_ARGS", "Channel is required", null)
            return
        }

        val isInstalled = when (channelName) {
            "alipay" -> isPackageInstalled("com.eg.android.AlipayGphone")
            "wechat" -> isPackageInstalled("com.tencent.mm")
            "unionPay" -> isPackageInstalled("com.unionpay")
            else -> false
        }

        result.success(isInstalled)
    }

    private fun handleInitSdk(call: MethodCall, result: MethodChannel.Result) {
        alipayAppId = call.argument<String>("alipayAppId")
        wechatAppId = call.argument<String>("wechatAppId")
        unionPayTnMode = call.argument<String>("unionPayTnMode")

        wechatAppId?.let { appId ->
            MultiPayPlugin.wechatAppId = appId
            val api = WXAPIFactory.createWXAPI(context, appId)
            api.registerApp(appId)
        }

        result.success(null)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        when (requestCode) {
            UNIONPAY_REQUEST_CODE -> {
                val status = when (resultCode) {
                    Activity.RESULT_OK -> "success"
                    Activity.RESULT_CANCELED -> "cancelled"
                    else -> "failed"
                }
                pendingResult?.success(mapOf("channel" to "unionPay", "status" to status))
                pendingResult = null
                return true
            }
        }
        return false
    }

    private fun checkWechatResult() {
        if (!isWechatPayPending || pendingResult == null) return

        val result = WechatResultHolder.lastResult
        if (result != null) {
            WechatResultHolder.lastResult = null
            pendingResult?.success(result)
            pendingResult = null
            isWechatPayPending = false
        }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            context.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun parseOrderInfo(jsonString: String): Map<String, Any> {
        return try {
            val jsonObject = org.json.JSONObject(jsonString)
            val map = mutableMapOf<String, Any>()
            jsonObject.keys().forEach { key ->
                map[key] = jsonObject.get(key)
            }
            map
        } catch (e: Exception) {
            emptyMap()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        currentActivity = binding.activity
        binding.addActivityResultListener(this)
        binding.lifecycle.addObserver(LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                checkWechatResult()
            }
        })
    }

    override fun onDetachedFromActivityForConfigChanges() {
        currentActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        currentActivity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        currentActivity = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }
}