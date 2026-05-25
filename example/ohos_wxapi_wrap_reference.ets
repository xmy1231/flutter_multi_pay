// 参考文件：创建为 ohos/entry/src/main/ets/utils/WXApiWrap.ets
// 微信 SDK 的 API 包装器，用于接收微信支付结果回调

import * as wxopensdk from '@tencent/wechat_open_sdk';

export type OnWXResp = (resp: wxopensdk.BaseResp) => void;

class WXApiEventHandlerImpl implements wxopensdk.WXApiEventHandler {
  private onRespCallbacks: Map<OnWXResp, OnWXResp> = new Map();

  registerOnWXRespCallback(on: OnWXResp): void {
    this.onRespCallbacks.set(on, on);
  }

  unregisterOnWXRespCallback(on: OnWXResp): void {
    this.onRespCallbacks.delete(on);
  }

  onReq(req: wxopensdk.BaseReq): void {
    // 处理来自微信的请求（可忽略）
  }

  onResp(resp: wxopensdk.BaseResp): void {
    this.onRespCallbacks.forEach((on) => {
      on(resp);
    });
  }
}

export const WXEventHandler = new WXApiEventHandlerImpl();

// 在应用启动时初始化：请替换 APP_ID 为你的微信移动应用 AppID
export const WXApi = wxopensdk.WXAPIFactory.createWXAPI('wxYOUR_APP_ID_HERE');
