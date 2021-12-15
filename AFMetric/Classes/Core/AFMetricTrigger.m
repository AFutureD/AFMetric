//
//  AFMetricTrigger.m
//  AFTracker
//
//  Created by AFuture on 2021/10/29.
//

#import "AFMetricTrigger.h"
#import "AFMetricProtocol.h"
#import "AFMetricAction.h"
#import "AFMetricDefine.h"
#import "AFFoundationKit.h"

@interface AFMetricTrigger ()

@property (nonatomic, copy) AFMetricActionReplyBlock actionReplyBlock;

@end

@implementation AFMetricTrigger

- (instancetype)initTriggerForTarget:(nullable id)target
                       hookSelector:(SEL)selector
                        withOptions:(AOPOptions)options
                        withActions:(AFMetricAction *)block
                              error:(NSError **)error {
    if (self = [super init]) {
        [target aop_hookSelector:selector withOptions:options usingBlock:^(id<AFAOPInfoProtocol> aspectInfo) {
            // 使用异步 1706.13ms -> 1458.32ms
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                AFLogDebug(@"AFMetric triggered %@", aspectInfo.instance);
                block.actionBlock(aspectInfo, self.actionReplyBlock);
            });
        } error:error];
    }
    return self;
}

+ (void)triggerEventWithValues:(NSDictionary *)values {
    [values enumerateKeysAndObjectsUsingBlock:^(NSString * key, id  _Nonnull obj, BOOL * _Nonnull stop) {

        NSString * eventId    = [obj objectForKey:@"id"];
        NSDictionary * attr   = [obj objectForKey:@"attr"];
        NSDictionary * infos  = [obj objectForKey:@"infos"];
        NSString * identifier = [obj objectForKey:@"identifier"];

        if ([key isEqualToString:AFMetricTriggerTypeTrack]){
            AFLogDebug(@"AFMetric trigger event send %@", eventId );
            [[self class] sendEvent:eventId withValues:attr infos:infos identifier:identifier];
        } else if ([key isEqualToString:AFMetricTriggerTypeLink]) {

        } else if ([key isEqualToString:AFMetricTriggerTypeAssert]) {

        } else {
            AFLogDebug(@"AFMetric trigger event send skipped.");
        }
    }];
}

+ (void)sendEvent:(NSString *)evnetId withValues:(NSDictionary *)values infos:(NSDictionary *)infos identifier:(NSString *)identifier {
    if (!evnetId || !values) {
        return;
    }
    AFLogDebug(@"AFMetric send %@ with %@", evnetId, values);
//    [TYSmartBusinessTracker trackEvent:evnetId attributes:values infos:infos forIdentifier:identifier];
    
}

- (AFMetricActionReplyBlock)actionReplyBlock {
    if (!_actionReplyBlock) {
        af_weakify(self);
        _actionReplyBlock = ^(NSDictionary * reply) {
            AFLogDebug(@"AFMetric trigger reply: %@", reply);
            af_strongify(self);
            [[self class] triggerEventWithValues:reply];
        };
    }
    return _actionReplyBlock;
}

@end
