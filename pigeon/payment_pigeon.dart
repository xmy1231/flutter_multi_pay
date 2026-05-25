import 'package:pigeon/pigeon.dart';

class PlatformConfig {
  final String? alipayAppId;
  final String? wechatAppId;
  final String? unionPayTnMode;

  const PlatformConfig({
    this.alipayAppId,
    this.wechatAppId,
    this.unionPayTnMode,
  });
}

@HostApi()
abstract class PaymentHostApi {
  /// 发起支付
  /// [channel] - 支付渠道: alipay, wechat, unionPay
  /// [orderInfo] - 订单信息（服务端签名后的订单数据）
  /// 返回支付结果
  Future<Map<Object?, Object?>> pay(String channel, String orderInfo);

  /// 检查支付App是否安装
  Future<bool> isAppInstalled(String channel);

  /// 初始化SDK配置
  Future<void> initSdk(PlatformConfig config);
}