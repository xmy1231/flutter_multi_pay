#import <Foundation/Foundation.h>

@protocol WxPayDelegate <NSObject>
- (void)onWechatPayResponseWithErrCode:(int)errCode errStr:(NSString *)errStr;
@end
