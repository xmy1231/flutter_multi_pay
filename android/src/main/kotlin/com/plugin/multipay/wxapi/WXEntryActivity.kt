package com.plugin.multipay.wxapi

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import com.plugin.multipay.MultiPayPlugin
import com.tencent.mm.opensdk.modelbase.BaseReq
import com.tencent.mm.opensdk.modelbase.BaseResp
import com.tencent.mm.opensdk.openapi.IWXAPI
import com.tencent.mm.opensdk.openapi.IWXAPIEventHandler
import com.tencent.mm.opensdk.openapi.WXAPIFactory

class WXEntryActivity : Activity(), IWXAPIEventHandler {

    private lateinit var api: IWXAPI

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val appId = MultiPayPlugin.wechatAppId
        if (appId == null) {
            finish()
            return
        }

        api = WXAPIFactory.createWXAPI(this, appId)
        api.handleIntent(intent, this)
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        intent?.let { api.handleIntent(it, this) }
    }

    override fun onReq(req: BaseReq) {
    }

    override fun onResp(resp: BaseResp) {
        val status = when (resp.errCode) {
            BaseResp.ErrCode.ERR_OK -> "success"
            BaseResp.ErrCode.ERR_USER_CANCEL -> "cancelled"
            else -> "failed"
        }

        val result = mapOf(
            "channel" to "wechat",
            "status" to status,
            "errCode" to resp.errCode,
            "errStr" to (resp.errStr ?: "")
        )

        WechatResultHolder.lastResult = result
        finish()
    }
}

object WechatResultHolder {
    var lastResult: Map<String, Any>? = null
}