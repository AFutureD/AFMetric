//
//  AFMetricTrigger.h
//  AFTracker
//
//  Created by AFuture on 2021/10/29.
//

#import <Foundation/Foundation.h>
#import "AFMetricAction.h"
#import "AFMetricProtocol.h"
#import "NSObject+AFAOP.h"

NS_ASSUME_NONNULL_BEGIN

@interface AFMetricTrigger : NSObject

- (instancetype)initTriggerForTarget:(nullable id)target
                        hookSelector:(SEL)selector
                         withOptions:(AOPOptions)options
                         withActions:(AFMetricAction *)block
                               error:(NSError **)error;

+ (void)sendEvent:(NSString *)evnetId withValues:(NSDictionary *)values infos:(NSDictionary *)infos identifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
