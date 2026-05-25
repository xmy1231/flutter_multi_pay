enum PaymentChannel {
  alipay,
  wechat,
  unionPay,
}

extension PaymentChannelExtension on PaymentChannel {
  String get name {
    switch (this) {
      case PaymentChannel.alipay:
        return 'alipay';
      case PaymentChannel.wechat:
        return 'wechat';
      case PaymentChannel.unionPay:
        return 'unionPay';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentChannel.alipay:
        return '支付宝';
      case PaymentChannel.wechat:
        return '微信支付';
      case PaymentChannel.unionPay:
        return '银联云闪付';
    }
  }

  String get iconName {
    switch (this) {
      case PaymentChannel.alipay:
        return 'alipay';
      case PaymentChannel.wechat:
        return 'wechat';
      case PaymentChannel.unionPay:
        return 'unionpay';
    }
  }

  String? get appScheme {
    switch (this) {
      case PaymentChannel.alipay:
        return 'alipays';
      case PaymentChannel.wechat:
        return '';
      case PaymentChannel.unionPay:
        return 'uppay';
    }
  }

  static PaymentChannel? fromString(String name) {
    switch (name.toLowerCase()) {
      case 'alipay':
        return PaymentChannel.alipay;
      case 'wechat':
        return PaymentChannel.wechat;
      case 'unionpay':
      case 'union_pay':
        return PaymentChannel.unionPay;
      default:
        return null;
    }
  }
}
