// 此文件为参考模板。
// 在 example/ 目录下执行 fvm flutter create --platforms ohos . 后，
// 将生成的 ohos/entry/src/main/ets/entryability/EntryAbility.ets
// 替换为以下内容，或手动合并 handleWant 回调逻辑。

import UIAbility from '@ohos.app.ability.UIAbility';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import { MultiPayPlugin } from '@ohos/multi_pay';
import * as wxopensdk from '@tencent/wechat_open_sdk';
import { WXApi, WXEventHandler } from '../utils/WXApiWrap'; // 见下方说明

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    MultiPayPlugin.handleWant(want);
    WXApi.handleWant?.(want, WXEventHandler);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    MultiPayPlugin.handleWant(want);
    WXApi.handleWant?.(want, WXEventHandler);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err, data) => {});
  }
}
