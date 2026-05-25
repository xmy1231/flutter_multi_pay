import { FlutterPlugin, FlutterPluginBinding, MethodCall, MethodChannel, MethodResult, MethodCallHandler } from '@ohos/flutter_ohos';
import { AbilityAware, AbilityPluginBinding } from '@ohos/flutter_ohos';
import { AlipayHelper } from './AlipayHelper';
import { WechatHelper, getWXEventHandler } from './WechatHelper';
import { UnionPayHelper } from './UnionPayHelper';
import bundleManager from '@ohos.bundle.bundleManager';
import Want from '@ohos.app.ability.Want';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';

const CHANNEL_NAME = 'multi_pay_channel';
const CALLBACK_CHANNEL = 'multi_pay_callback';

export class MultiPayPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  getUniqueClassName(): string {
    return 'MultiPayPlugin';
  }

  private channel: MethodChannel | null = null;
  private callbackEventSink: MethodResult | null = null;
  private applicationContext: common.Context | null = null;
  private abilityContext: common.UIAbilityContext | null = null;

  private alipayHelper: AlipayHelper = new AlipayHelper();
  private wechatHelper: WechatHelper = new WechatHelper();
  private unionPayHelper: UnionPayHelper = new UnionPayHelper();

  private static pendingResult: MethodResult | null = null;
  private static pendingChannel: string | null = null;
  private static instance: MultiPayPlugin | null = null;

  static handleWant(want: Want): void {
    const inst = MultiPayPlugin.instance;
    if (inst == null) return;

    const uri = want?.uri;

    if (uri != null && uri.includes('uppayresult')) {
      inst.unionPayHelper.handleWant(uri, (result) => {
        MultiPayPlugin.pendingResult?.success(result);
        MultiPayPlugin.pendingResult = null;
        MultiPayPlugin.pendingChannel = null;
      });
    }

    const wxapi = inst.wechatHelper.getWXApi();
    const handler = getWXEventHandler();
    if (wxapi != null && handler != null) {
      wxapi.handleWant(want, handler);
    }
  }

  onNewWant(want: Want): void {
    MultiPayPlugin.handleWant(want);
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    MultiPayPlugin.instance = this;
    this.applicationContext = binding.getApplicationContext();

    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);

    const eventChannel = new MethodChannel(binding.getBinaryMessenger(), CALLBACK_CHANNEL);
    // EventChannel is used to forward callback URIs to Dart side if needed
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'initSdk':
        this.handleInitSdk(call, result);
        break;
      case 'pay':
        this.handlePay(call, result);
        break;
      case 'isAppInstalled':
        this.handleIsAppInstalled(call, result);
        break;
      default:
        result.notImplemented();
    }
  }

  private handleInitSdk(call: MethodCall, result: MethodResult): void {
    this.alipayHelper.setAppId(call.argument('alipayAppId') as string ?? '');
    this.wechatHelper.setAppId(call.argument('wechatAppId') as string ?? '');
    this.unionPayHelper.setScheme(call.argument('unionPayScheme') as string ?? 'uppay');
    result.success(null);
  }

  private handlePay(call: MethodCall, result: MethodResult): void {
    const channelName = call.argument('channel') as string;
    const orderInfo = call.argument('orderInfo') as string;

    if (channelName == null || orderInfo == null) {
      result.error('INVALID_ARGS', 'Channel and orderInfo are required', null);
      return;
    }

    switch (channelName) {
      case 'alipay':
        this.alipayHelper.pay(orderInfo, result);
        break;
      case 'wechat':
        MultiPayPlugin.pendingResult = result;
        MultiPayPlugin.pendingChannel = 'wechat';
        this.wechatHelper.pay(orderInfo, this.abilityContext, (resp) => {
          const status = this.wechatHelper.parseRespStatus(resp);
          MultiPayPlugin.pendingResult?.success({
            channel: 'wechat',
            status: status,
            errCode: resp.errCode,
            errStr: resp.errStr ?? ''
          });
          MultiPayPlugin.pendingResult = null;
          MultiPayPlugin.pendingChannel = null;
        });
        break;
      case 'unionPay':
        MultiPayPlugin.pendingResult = result;
        MultiPayPlugin.pendingChannel = 'unionPay';
        this.unionPayHelper.pay(orderInfo, '00', this.abilityContext);
        // Result will come via handleWant -> onNewWant
        break;
      default:
        result.error('UNKNOWN_CHANNEL', 'Unknown channel: ' + channelName, null);
    }
  }

  private handleIsAppInstalled(call: MethodCall, result: MethodResult): void {
    const channelName = call.argument('channel') as string;
    const bundleName = this.getBundleName(channelName);
    if (bundleName == null) {
      result.success(false);
      return;
    }
    // Try to get bundle info to check if app is installed
    try {
      bundleManager.getBundleInfo(bundleName, 0)
        .then(() => result.success(true))
        .catch(() => result.success(false));
    } catch (e) {
      result.success(false);
    }
  }

  private getBundleName(channel: string): string | null {
    switch (channel) {
      case 'alipay': return 'com.eg.android.AlipayGphone';
      case 'wechat': return 'com.tencent.mm';
      case 'unionPay': return 'com.unionpay';
      default: return null;
    }
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.abilityContext = binding.getAbility().context;
    this.alipayHelper.init(this.abilityContext as common.UIAbilityContext);
  }

  onDetachedFromAbility(): void {
    this.abilityContext = null;
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
    MultiPayPlugin.instance = null;
  }
}
