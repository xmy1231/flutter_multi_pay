#import <Flutter/Flutter.h>
#import "WxPayDelegate.h"

@interface WxPayBridge : NSObject

+ (void)setWxDelegate:(id<WxPayDelegate>)delegate;
+ (id<WxPayDelegate>)wxDelegate;

+ (BOOL)isWxAppInstalled;
+ (BOOL)registerApp:(NSString *)appId universalLink:(NSString *)universalLink;
+ (void)sendPayReqWithPartnerId:(NSString *)partnerId
                       prepayId:(NSString *)prepayId
                        package:(NSString *)package
                       nonceStr:(NSString *)nonceStr
                    timeStamp:(UInt32)timeStamp
                           sign:(NSString *)sign;
+ (BOOL)handleOpenURL:(NSURL *)url;

@end
