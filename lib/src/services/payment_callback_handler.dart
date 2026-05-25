import 'dart:async';
import 'package:app_links/app_links.dart';
import '../enums/payment_channel.dart';

class PaymentCallbackResult {
  final PaymentChannel channel;
  final String status;
  final String? errorCode;
  final String? errorMessage;
  final Map<String, dynamic>? extra;

  PaymentCallbackResult({
    required this.channel,
    required this.status,
    this.errorCode,
    this.errorMessage,
    this.extra,
  });

  factory PaymentCallbackResult.fromMap(Map<String, dynamic> map) {
    final channelStr = map['channel'] as String? ?? '';
    final channel =
        PaymentChannelExtension.fromString(channelStr) ?? PaymentChannel.alipay;

    return PaymentCallbackResult(
      channel: channel,
      status: map['status'] as String? ?? 'failed',
      errorCode: map['errorCode']?.toString(),
      errorMessage: map['errorMessage'] as String?,
      extra: map['extra'] as Map<String, dynamic>?,
    );
  }
}

class PaymentCallbackHandler {
  static final PaymentCallbackHandler _instance =
      PaymentCallbackHandler._internal();
  factory PaymentCallbackHandler() => _instance;
  PaymentCallbackHandler._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _uriSubscription;
  final _resultController = StreamController<PaymentCallbackResult>.broadcast();

  Stream<PaymentCallbackResult> get onCallback => _resultController.stream;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleCallback(initialUri);
      }
    } catch (e) {
      // Initial URI not available
    }

    _uriSubscription = _appLinks.uriLinkStream.listen(_handleCallback);
  }

  void _handleCallback(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();

    if (scheme == 'alipays' || host == 'safepay') {
      _handleAlipayCallback(uri);
    } else if (scheme == 'weixin' ||
        scheme == 'wxd' ||
        host.startsWith('wxd')) {
      _handleWechatCallback(uri);
    } else if (scheme == 'uppay' ||
        scheme == 'uppays' ||
        host.startsWith('uppay')) {
      _handleUnionPayCallback(uri);
    }
  }

  void _handleAlipayCallback(Uri uri) {
    final params = uri.queryParameters;
    final resultStatus = params['resultStatus'];
    final result = params['result'];

    String status;
    String? errorCode;
    String? errorMessage;

    switch (resultStatus) {
      case '9000':
        status = 'success';
        break;
      case '6001':
        status = 'cancelled';
        errorCode = '6001';
        errorMessage = '用户中途取消';
        break;
      case '4000':
        status = 'failed';
        errorCode = '4000';
        errorMessage = '订单支付失败';
        break;
      case '5000':
        status = 'cancelled';
        errorCode = '5000';
        errorMessage = '用户中途取消';
        break;
      case '6002':
        status = 'failed';
        errorCode = '6002';
        errorMessage = '网络连接出错';
        break;
      default:
        status = 'failed';
        errorCode = resultStatus;
        errorMessage = result;
    }

    _resultController.add(PaymentCallbackResult(
      channel: PaymentChannel.alipay,
      status: status,
      errorCode: errorCode,
      errorMessage: errorMessage,
      extra: {'rawUri': uri.toString()},
    ));
  }

  void _handleWechatCallback(Uri uri) {
    final params = uri.queryParameters;
    final code = params['code'];
    final state = params['state'];

    if (state == 'wechat_pay') {
      _resultController.add(PaymentCallbackResult(
        channel: PaymentChannel.wechat,
        status: 'pending',
        extra: {'code': code, 'rawUri': uri.toString()},
      ));
    } else {
      final errCode = params['err_code'];
      final errMsg = params['err_msg'];

      _resultController.add(PaymentCallbackResult(
        channel: PaymentChannel.wechat,
        status: errCode == '0' ? 'success' : 'failed',
        errorCode: errCode,
        errorMessage: errMsg,
        extra: {'rawUri': uri.toString()},
      ));
    }
  }

  void _handleUnionPayCallback(Uri uri) {
    final params = uri.queryParameters;
    final code = params['code'];
    final message = params['message'];

    String status;
    if (code == 'success') {
      status = 'success';
    } else if (code == 'cancel') {
      status = 'cancelled';
    } else {
      status = 'failed';
    }

    _resultController.add(PaymentCallbackResult(
      channel: PaymentChannel.unionPay,
      status: status,
      errorCode: code,
      errorMessage: message,
      extra: {'rawUri': uri.toString()},
    ));
  }

  void dispose() {
    _uriSubscription?.cancel();
    _resultController.close();
  }
}
