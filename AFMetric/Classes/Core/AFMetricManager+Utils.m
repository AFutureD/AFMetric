//
//  AFMetricManager+Utils.m
//  AFMetricManager+Utils
//
//  Created by AFuture D. on 2021/12/25.
//

#import "AFMetricManager+Utils.h"
#import "AFMetricTrigger.h"

@implementation AFMetricManager (Utils)

- (void)triggerEvent:(NSString *)evnetId withValues:(NSDictionary *)values {
    [[AFMetricTrigger class] sendEvent:evnetId withValues:values infos:@{} identifier:@""];
}

@end
