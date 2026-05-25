#import "WxPayBridge.h"
#import "WXApi.h"
#import "WXApiObject.h"

static __weak id<WxPayDelegate> _wxDelegate;

@interface WxPayBridge () <WXApiDelegate>
@end

@implementation WxPayBridge

+ (id<WxPayDelegate>)wxDelegate {
    return _wxDelegate;
}

+ (void)setWxDelegate:(id<WxPayDelegate>)delegate {
    _wxDelegate = delegate;
}

+ (BOOL)isWxAppInstalled {
    return [WXApi isWXAppInstalled];
}

+ (BOOL)registerApp:(NSString *)appId universalLink:(NSString *)universalLink {
    return [WXApi registerApp:appId universalLink:universalLink];
}

+ (void)sendPayReqWithPartnerId:(NSString *)partnerId
                       prepayId:(NSString *)prepayId
                        package:(NSString *)package
                       nonceStr:(NSString *)nonceStr
                      timeStamp:(UInt32)timeStamp
                           sign:(NSString *)sign {
    PayReq *req = [[PayReq alloc] init];
    req.partnerId = partnerId;
    req.prepayId = prepayId;
    req.package = package;
    req.nonceStr = nonceStr;
    req.timeStamp = timeStamp;
    req.sign = sign;
    req.openID = @"";

    [WXApi sendReq:req completion:nil];
}

+ (BOOL)handleOpenURL:(NSURL *)url {
    return [WXApi handleOpenURL:url delegate:[WxPayBridge class].sharedDelegate];
}

+ (instancetype)sharedDelegate {
    static WxPayBridge *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[WxPayBridge alloc] init];
    });
    return shared;
}

#pragma mark - WXApiDelegate

- (void)onReq:(BaseReq *)req {
}

- (void)onResp:(BaseResp *)resp {
    if ([resp isKindOfClass:[PayResp class]]) {
        PayResp *payResp = (PayResp *)resp;
        [_wxDelegate onWechatPayResponseWithErrCode:payResp.errCode errStr:payResp.errStr ?: @""];
    }
}

@end
