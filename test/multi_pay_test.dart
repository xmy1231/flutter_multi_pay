import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_pay/multi_pay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PaymentChannel', () {
    test('fromString handles all channel names', () {
      expect(PaymentChannelExtension.fromString('alipay'), PaymentChannel.alipay);
      expect(PaymentChannelExtension.fromString('wechat'), PaymentChannel.wechat);
      expect(PaymentChannelExtension.fromString('unionPay'), PaymentChannel.unionPay);
    });

    test('fromString case insensitive', () {
      expect(PaymentChannelExtension.fromString('ALIPAY'), PaymentChannel.alipay);
      expect(PaymentChannelExtension.fromString('WeChat'), PaymentChannel.wechat);
    });

    test('displayName returns Chinese names', () {
      expect(PaymentChannel.alipay.displayName, '支付宝');
      expect(PaymentChannel.wechat.displayName, '微信支付');
      expect(PaymentChannel.unionPay.displayName, '银联云闪付');
    });

    test('fromString returns null for unknown channel', () {
      expect(PaymentChannelExtension.fromString('unknown'), isNull);
    });
  });

  group('PaymentResult', () {
    test('success factory creates success result', () {
      final result = PaymentResult.success(PaymentChannel.alipay, orderId: '123');
      expect(result.isSuccess, isTrue);
      expect(result.channel, PaymentChannel.alipay);
      expect(result.orderId, '123');
    });

    test('failed factory creates failed result', () {
      final result = PaymentResult.failed(PaymentChannel.wechat, 'ERR', 'Error msg');
      expect(result.isFailed, isTrue);
      expect(result.errorCode, 'ERR');
      expect(result.errorMessage, 'Error msg');
    });

    test('cancelled factory creates cancelled result', () {
      final result = PaymentResult.cancelled(PaymentChannel.unionPay);
      expect(result.isCancelled, isTrue);
    });

    test('fromMap parses correctly', () {
      final map = {'channel': 'alipay', 'status': 'success', 'orderId': 'abc'};
      final result = PaymentResult.fromMap(map);
      expect(result.channel, PaymentChannel.alipay);
      expect(result.isSuccess, isTrue);
      expect(result.orderId, 'abc');
    });

    test('fromMap handles failed status', () {
      final map = {'channel': 'wechat', 'status': 'failed', 'errorCode': 'E1'};
      final result = PaymentResult.fromMap(map);
      expect(result.isFailed, isTrue);
      expect(result.errorCode, 'E1');
    });

    test('fromMap handles unknown channel gracefully', () {
      final map = {'channel': 'unknown', 'status': 'success'};
      final result = PaymentResult.fromMap(map);
      expect(result.channel, PaymentChannel.alipay);
    });

    test('toMap produces correct output', () {
      final result = PaymentResult.success(PaymentChannel.wechat, orderId: '456');
      final map = result.toMap();
      expect(map['channel'], 'wechat');
      expect(map['status'], 'success');
      expect(map['orderId'], '456');
    });
  });

  group('MultiPay', () {
    test('pay returns success result from MethodChannel', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('multi_pay_channel'),
              (MethodCall methodCall) async {
        expect(methodCall.method, 'pay');
        expect(methodCall.arguments['channel'], 'alipay');
        expect(methodCall.arguments['orderInfo'], '{"order":"test"}');
        return {'channel': 'alipay', 'status': 'success', 'orderId': 'abc123'};
      });

      final result = await MultiPay.pay(
        channel: PaymentChannel.alipay,
        orderInfo: '{"order":"test"}',
      );

      expect(result.isSuccess, isTrue);
      expect(result.channel, PaymentChannel.alipay);
      expect(result.orderId, 'abc123');
    });

    test('pay returns failed result on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('multi_pay_channel'),
              (MethodCall methodCall) async {
        if (methodCall.method == 'isAppInstalled') return true;
        return {'status': 'failed', 'errorCode': 'NETWORK_ERROR', 'errorMessage': 'Connection failed'};
      });

      final result = await MultiPay.pay(
        channel: PaymentChannel.wechat,
        orderInfo: '{}',
      );

      expect(result.isFailed, isTrue);
      expect(result.errorCode, 'NETWORK_ERROR');
    });

    test('pay returns APP_NOT_INSTALLED when wechat not installed', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('multi_pay_channel'),
              (MethodCall methodCall) async {
        if (methodCall.method == 'isAppInstalled') return false;
        return {'status': 'success'};
      });

      final result = await MultiPay.pay(
        channel: PaymentChannel.wechat,
        orderInfo: '{}',
      );

      expect(result.isFailed, isTrue);
      expect(result.errorCode, 'APP_NOT_INSTALLED');
      expect(result.errorMessage, '微信客户端未安装');
    });
  });
}
