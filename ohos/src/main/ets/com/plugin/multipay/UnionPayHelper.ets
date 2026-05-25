import { UPPayment, UPPayResult, UPPayResultStatus } from 'uppayment';
import common from '@ohos.app.ability.common';

export interface PaymentCallbackResult {
  channel: string;
  status: string;
  data: string | null;
}

export class UnionPayHelper {
  private upPayment = new UPPayment();
  private unionPayScheme: string = 'uppay';

  setScheme(scheme: string): void {
    this.unionPayScheme = scheme;
  }

  pay(tn: string, mode: string, context: common.UIAbilityContext | null): void {
    if (context == null) return;
    this.upPayment.startPay(tn, mode, this.unionPayScheme, context, '');
  }

  handleWant(uri: string, callback: (result: PaymentCallbackResult) => void): void {
    this.upPayment.handlePaymentResult(uri, (payResult: UPPayResult) => {
      const status = this.mapStatus(payResult.code);
      const result: PaymentCallbackResult = {
        channel: 'unionPay',
        status: status,
        data: payResult.data ?? null,
      };
      callback(result);
    });
  }

  private mapStatus(code: UPPayResultStatus | undefined): string {
    switch (code) {
      case UPPayResultStatus.SUCCESS: return 'success';
      case UPPayResultStatus.CANCEL: return 'cancelled';
      default: return 'failed';
    }
  }
}
