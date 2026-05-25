import { MethodResult } from '@ohos/flutter_ohos';
import { Pay } from '@cashier_alipay/cashiersdk';
import common from '@ohos.app.ability.common';
import bundleManager from '@ohos.bundle.bundleManager';

export class AlipayHelper {
  private payInstance: Pay = new Pay();

  setAppId(appId: string): void {
    this.appId = appId;
  }

  private appId: string = '';

  init(context: common.UIAbilityContext): void {
    this.payInstance.registerApp(this.appId);
  }

  async pay(orderInfo: string, result: MethodResult): Promise<void> {
    try {
      const installed = await bundleManager.getBundleInfo('com.eg.android.AlipayGphone', 0)
        .then(() => true)
        .catch(() => false);
      if (!installed) {
        result.success({
          channel: 'alipay',
          status: 'failed',
          errorCode: 'APP_NOT_INSTALLED',
          errorMessage: '支付宝客户端未安装',
        });
        return;
      }

      const payResult: Map<string, string> = await this.payInstance.pay(orderInfo);
      const resultStatus = payResult.get('resultStatus') ?? '';
      const memo = payResult.get('memo') ?? '';
      const { status, errorCode } = this.parseResult(resultStatus);
      result.success({
        channel: 'alipay',
        status: status,
        errorCode: errorCode,
        errorMessage: memo,
        resultStatus: resultStatus,
      });
    } catch (error) {
      result.success({
        channel: 'alipay',
        status: 'failed',
        errorCode: 'INVOKE_FAIL',
        errorMessage: (error as Error).message,
      });
    }
  }

  private parseResult(resultStatus: string): { status: string, errorCode: string | null } {
    switch (resultStatus) {
      case '9000': return { status: 'success', errorCode: null };
      case '6001': return { status: 'cancelled', errorCode: null };
      case '6002': return { status: 'failed', errorCode: 'NETWORK_ERROR' };
      case '4000': return { status: 'failed', errorCode: 'PAY_FAILED' };
      case '8000': return { status: 'pending', errorCode: 'PAYMENT_PROCESSING' };
      case '5000': return { status: 'failed', errorCode: 'DOUBLE_REQUEST' };
      default: return { status: 'failed', errorCode: 'PAYMENT_ERROR' };
    }
  }
}
