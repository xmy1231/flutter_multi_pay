import * as wxopensdk from '@tencent/wechat_open_sdk';
import common from '@ohos.app.ability.common';

export type OnWXRespCallback = (resp: wxopensdk.BaseResp) => void;

class WXApiEventHandlerImpl implements wxopensdk.WXApiEventHandler {
  private onRespCallbacks: Map<OnWXRespCallback, OnWXRespCallback> = new Map();

  registerOnWXRespCallback(on: OnWXRespCallback): void {
    this.onRespCallbacks.set(on, on);
  }

  unregisterOnWXRespCallback(on: OnWXRespCallback): void {
    this.onRespCallbacks.delete(on);
  }

  onReq(req: wxopensdk.BaseReq): void {
    // Handle requests from WeChat if needed
  }

  onResp(resp: wxopensdk.BaseResp): void {
    this.onRespCallbacks.forEach((on) => {
      on(resp);
    });
  }
}

const WXEventHandler = new WXApiEventHandlerImpl();

export function getWXEventHandler(): WXApiEventHandlerImpl {
  return WXEventHandler;
}

export class WechatHelper {
  private appId: string = '';
  private wxApi: wxopensdk.WXApi | null = null;
  private currentCallback: OnWXRespCallback | null = null;

  getWXApi(): wxopensdk.WXApi | null {
    return this.wxApi;
  }

  setAppId(appId: string): void {
    this.appId = appId;
    if (appId != null && appId !== '') {
      this.wxApi = wxopensdk.WXAPIFactory.createWXAPI(appId);
    }
  }

  async pay(orderInfo: string, context: common.UIAbilityContext | null, callback: OnWXRespCallback): Promise<void> {
    if (this.wxApi == null || context == null) {
      const resp = new wxopensdk.PayResp();
      resp.errCode = wxopensdk.ErrCode.ERR_COMM;
      callback(resp);
      return;
    }

    this.currentCallback = callback;
    WXEventHandler.registerOnWXRespCallback(this.onResp.bind(this));

    try {
      const order: Record<string, string> = JSON.parse(orderInfo);
      const req = new wxopensdk.PayReq();
      req.appId = this.appId;
      req.partnerId = order.partnerId ?? '';
      req.prepayId = order.prepayId ?? '';
      req.nonceStr = order.nonceStr ?? order.noncestr ?? '';
      req.timeStamp = order.timeStamp ?? order.timestamp ?? '';
      req.sign = order.sign ?? '';
      req.packageValue = 'Sign=WXPay';

      const finished = await this.wxApi.sendReq(context, req);
      if (!finished) {
        WXEventHandler.unregisterOnWXRespCallback(this.onResp.bind(this));
        this.currentCallback = null;
        const resp = new wxopensdk.PayResp();
        resp.errCode = wxopensdk.ErrCode.ERR_COMM;
        callback(resp);
      }
    } catch (e) {
      WXEventHandler.unregisterOnWXRespCallback(this.onResp.bind(this));
      this.currentCallback = null;
      const resp = new wxopensdk.PayResp();
      resp.errCode = wxopensdk.ErrCode.ERR_COMM;
      callback(resp);
    }
  }

  private onResp(resp: wxopensdk.BaseResp): void {
    WXEventHandler.unregisterOnWXRespCallback(this.onResp.bind(this));
    const cb = this.currentCallback;
    this.currentCallback = null;
    if (cb != null) {
      cb(resp);
    }
  }

  parseRespStatus(resp: wxopensdk.BaseResp): string {
    if (resp.errCode === wxopensdk.ErrCode.ERR_OK) {
      return 'success';
    } else if (resp.errCode === wxopensdk.ErrCode.ERR_USER_CANCEL) {
      return 'cancelled';
    }
    return 'failed';
  }
}
