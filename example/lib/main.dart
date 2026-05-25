import 'package:flutter/material.dart';
import 'package:multi_pay/multi_pay.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MultiPay Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _initPayment();
  }

  Future<void> _initPayment() async {
    await MultiPay.init(
      alipayAppId: '2021001234567890',
      wechatAppId: 'wxd930ea5d5a258f4',
      wechatUniversalLink: 'https://your-app.com/ulink/',
      alipayScheme: 'yourAlipayScheme',
      unionPayScheme: 'yourUnionPayScheme',
      unionPayTnMode: '00',
    );

    MultiPay.onCallback.listen((result) {
      _handlePaymentCallback(result);
    });
  }

  void _handlePaymentCallback(PaymentCallbackResult result) {
    final statusText = result.status == 'success'
        ? '支付成功'
        : result.status == 'cancelled'
            ? '支付取消'
            : '支付失败';

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$statusText - ${result.channel.displayName}'),
        backgroundColor:
            result.status == 'success' ? Colors.green : Colors.orange,
      ),
    );
  }

  Future<void> _pay(PaymentChannel channel) async {
    final orderInfo = _buildOrderInfo(channel);
    final result = await MultiPay.pay(channel: channel, orderInfo: orderInfo);

    if (!context.mounted) return;

    if (result.errorCode == 'APP_NOT_INSTALLED') {
      _showInstallPrompt(result);
      return;
    }

    _showResultDialog(result);
  }

  void _showInstallPrompt(PaymentResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('未安装客户端'),
          ],
        ),
        content: Text('请先安装${result.channel.displayName}客户端'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  String _buildOrderInfo(PaymentChannel channel) {
    final now = DateTime.now();
    final timestamp =
        '${now.year}-${_pad(now.month)}-${_pad(now.day)} ${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}';
    final outTradeNo = 'MP$timestamp${_pad(now.millisecond)}'
        .replaceAll(RegExp(r'[\s:-]'), '');
    final timeSec = (now.millisecondsSinceEpoch ~/ 1000).toString();
    final prepayId = 'wx${outTradeNo.substring(2)}';

    switch (channel) {
      case PaymentChannel.alipay:
        return '''{"app_id":"2021002197609023","method":"alipay.trade.app.pay","charset":"utf-8","sign_type":"RSA2","sign":"MOCK_SIGN_$outTradeNo","timestamp":"$timestamp","version":"1.0","biz_content":"{\\"body\\":\\"Flutter多商户订单\\",\\"subject\\":\\"商品支付\\",\\"out_trade_no\\":\\"$outTradeNo\\",\\"timeout_express\\":\\"30m\\",\\"total_amount\\":\\"99.00\\",\\"product_code\\":\\"QUICK_MSECURITY_PAY\\"}"}''';
      case PaymentChannel.wechat:
        return '''{"appId":"wxd930ea5d5a258f4","partnerId":"1234567890","prepayId":"$prepayId","package":"Sign=WXPay","nonceStr":"${outTradeNo.substring(0, 16)}","timeStamp":"$timeSec","sign":"MOCK_SIGN_$outTradeNo","signType":"MD5"}''';
      case PaymentChannel.unionPay:
        return '''{"tn":"${outTradeNo}1234567890","mode":"00","orderId":"$outTradeNo","signMethod":"SHA256","txnAmt":"99","txnCurr":"CNY"}''';
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  void _showResultDialog(PaymentResult result) {
    final statusText = result.isSuccess
        ? '支付成功'
        : result.isCancelled
            ? '支付已取消'
            : '支付失败';

    final statusColor = result.isSuccess
        ? Colors.green
        : result.isCancelled
            ? Colors.orange
            : Colors.red;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.isSuccess
                  ? Icons.check_circle
                  : result.isCancelled
                      ? Icons.info
                      : Icons.error,
              color: statusColor,
            ),
            const SizedBox(width: 8),
            Text(statusText),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('支付渠道: ${result.channel.displayName}'),
            if (result.orderId != null) Text('订单号: ${result.orderId}'),
            if (result.errorCode != null) Text('错误码: ${result.errorCode}'),
            if (result.errorMessage != null)
              Text('错误信息: ${result.errorMessage}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _channelInfo(PaymentChannel channel) {
    switch (channel) {
      case PaymentChannel.alipay:
        return (Icons.payment, const Color(0xFF1677FF));
      case PaymentChannel.wechat:
        return (Icons.wechat, const Color(0xFF07C160));
      case PaymentChannel.unionPay:
        return (Icons.cloud, const Color(0xFFE60012));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('支付示例'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text('订单金额',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text(
              '¥99.00',
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 48),
            for (final channel in PaymentChannel.values) ...[
              _buildChannelButton(channel),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChannelButton(PaymentChannel channel) {
    final (icon, color) = _channelInfo(channel);
    return SizedBox(
      width: 260,
      child: ElevatedButton.icon(
        onPressed: () => _pay(channel),
        icon: Icon(icon),
        label: Text('${channel.displayName}支付  ¥99.00'),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }
}
