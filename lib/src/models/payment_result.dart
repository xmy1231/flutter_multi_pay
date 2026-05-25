import '../enums/payment_channel.dart';

enum PaymentStatus {
  success,
  failed,
  cancelled,
  pending,
}

class PaymentResult {
  final PaymentChannel channel;
  final PaymentStatus status;
  final String? orderId;
  final String? errorCode;
  final String? errorMessage;
  final Map<String, dynamic>? extra;

  const PaymentResult({
    required this.channel,
    required this.status,
    this.orderId,
    this.errorCode,
    this.errorMessage,
    this.extra,
  });

  bool get isSuccess => status == PaymentStatus.success;
  bool get isCancelled => status == PaymentStatus.cancelled;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isPending => status == PaymentStatus.pending;

  factory PaymentResult.success(PaymentChannel channel, {String? orderId, Map<String, dynamic>? extra}) {
    return PaymentResult(
      channel: channel,
      status: PaymentStatus.success,
      orderId: orderId,
      extra: extra,
    );
  }

  factory PaymentResult.failed(PaymentChannel channel, String code, String message, {Map<String, dynamic>? extra}) {
    return PaymentResult(
      channel: channel,
      status: PaymentStatus.failed,
      errorCode: code,
      errorMessage: message,
      extra: extra,
    );
  }

  factory PaymentResult.cancelled(PaymentChannel channel, {Map<String, dynamic>? extra}) {
    return PaymentResult(
      channel: channel,
      status: PaymentStatus.cancelled,
      extra: extra,
    );
  }

  factory PaymentResult.pending(PaymentChannel channel, {Map<String, dynamic>? extra}) {
    return PaymentResult(
      channel: channel,
      status: PaymentStatus.pending,
      extra: extra,
    );
  }

  factory PaymentResult.fromMap(Map<String, dynamic> map) {
    final channelStr = map['channel'] as String? ?? '';
    final channel = PaymentChannelExtension.fromString(channelStr) ?? PaymentChannel.alipay;

    final statusStr = map['status'] as String? ?? '';
    final status = _parseStatus(statusStr);

    return PaymentResult(
      channel: channel,
      status: status,
      orderId: map['orderId'] as String?,
      errorCode: map['errorCode'] as String?,
      errorMessage: map['errorMessage'] as String?,
      extra: map['extra'] as Map<String, dynamic>?,
    );
  }

  static PaymentStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return PaymentStatus.success;
      case 'failed':
      case 'fail':
        return PaymentStatus.failed;
      case 'cancelled':
      case 'cancel':
        return PaymentStatus.cancelled;
      case 'pending':
      default:
        return PaymentStatus.pending;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'channel': channel.name,
      'status': status.name,
      if (orderId != null) 'orderId': orderId,
      if (errorCode != null) 'errorCode': errorCode,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (extra != null) 'extra': extra,
    };
  }

  @override
  String toString() {
    return 'PaymentResult(channel: $channel, status: $status, orderId: $orderId, errorCode: $errorCode, errorMessage: $errorMessage)';
  }
}