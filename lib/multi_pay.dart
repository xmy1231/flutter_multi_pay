export 'src/enums/payment_channel.dart';
export 'src/models/payment_result.dart';
export 'src/services/payment_callback_handler.dart';

import 'package:multi_pay/src/enums/payment_channel.dart';
import 'package:multi_pay/src/models/payment_result.dart';
import 'package:multi_pay/src/services/payment_host_api.dart';
import 'package:multi_pay/src/services/payment_callback_handler.dart';

class MultiPay {
  static final PaymentHostApi _hostApi = PaymentHostApi();
  static final PaymentCallbackHandler _callbackHandler = PaymentCallbackHandler();

  static bool _initialized = false;

  static Future<void> init({
    String? alipayAppId,
    String? wechatAppId,
    String? unionPayTnMode,
    String? wechatUniversalLink,
    String? wechatScheme,
    String? alipayScheme,
    String? unionPayScheme,
  }) async {
    if (_initialized) return;

    await _callbackHandler.init();
    await _hostApi.initSdk(
      alipayAppId: alipayAppId,
      wechatAppId: wechatAppId,
      unionPayTnMode: unionPayTnMode,
      wechatUniversalLink: wechatUniversalLink,
      wechatScheme: wechatScheme,
      alipayScheme: alipayScheme,
      unionPayScheme: unionPayScheme,
    );

    _initialized = true;
  }

  static Stream<PaymentCallbackResult> get onCallback => _callbackHandler.onCallback;

  static Future<PaymentResult> pay({
    required PaymentChannel channel,
    required String orderInfo,
  }) async {
    if (channel == PaymentChannel.wechat) {
      final installed = await isAppInstalled(channel);
      if (!installed) {
        return PaymentResult.failed(channel, 'APP_NOT_INSTALLED', '微信客户端未安装');
      }
    }

    try {
      final response = await _hostApi.pay(channel.name, orderInfo);
      return PaymentResult.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      return PaymentResult.failed(channel, 'PAYMENT_ERROR', e.toString());
    }
  }

  static Future<bool> isAppInstalled(PaymentChannel channel) async {
    return await _hostApi.isAppInstalled(channel.name);
  }

  static Future<List<PaymentChannel>> getAvailableChannels() async {
    final List<PaymentChannel> available = [];

    for (final channel in PaymentChannel.values) {
      if (await isAppInstalled(channel)) {
        available.add(channel);
      }
    }

    return available;
  }
}