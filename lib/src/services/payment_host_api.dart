import 'package:flutter/services.dart';

class PaymentHostApi {
  static const MethodChannel _channel = MethodChannel('multi_pay_channel');

  Future<Map<Object?, Object?>> pay(String channel, String orderInfo) async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('pay', {
        'channel': channel,
        'orderInfo': orderInfo,
      });
      return result ?? {};
    } on PlatformException catch (e) {
      return {
        'status': 'failed',
        'errorCode': e.code,
        'errorMessage': e.message,
      };
    }
  }

  Future<bool> isAppInstalled(String channel) async {
    try {
      final result = await _channel.invokeMethod<bool>('isAppInstalled', {
        'channel': channel,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> initSdk({
    String? alipayAppId,
    String? wechatAppId,
    String? unionPayTnMode,
    String? wechatUniversalLink,
    String? wechatScheme,
    String? alipayScheme,
    String? unionPayScheme,
  }) async {
    try {
      await _channel.invokeMethod<void>('initSdk', {
        'alipayAppId': alipayAppId,
        'wechatAppId': wechatAppId,
        'unionPayTnMode': unionPayTnMode,
        'wechatUniversalLink': wechatUniversalLink,
        'wechatScheme': wechatScheme,
        'alipayScheme': alipayScheme,
        'unionPayScheme': unionPayScheme,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to initialize SDK: ${e.message}');
    }
  }
}