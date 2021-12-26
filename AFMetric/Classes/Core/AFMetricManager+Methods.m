//
//  AFMetricManager+Hook.m
//  AFMetricManager+Hook
//
//  Created by AFuture D. on 2021/12/25.
//

#import "AFMetricManager+Methods.h"
#import "AFMetricAction.h"
#import "AFFoundationKit.h"
#import "NSObject+AFPerformSelector.h"
#import "AFMetricTrigger.h"
#import "NSArray+AFMetric.h"

@implementation AFMetricManager (Methods)

#pragma mark - point 2 point

- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName methods:(NSArray<NSString *> *)methods {
    [methods enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self hookTarget:target withTrackerName:trackerName method:obj];
    }];
}

- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName method:(NSString *)method {
    [self hookTarget:target withTrackerName:trackerName method:method trackerMathod:[method copy]];
}

- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName methods:(NSArray<NSString *> *)methods trackerMathods:(NSArray<NSString *> *)trackerMathods {
    [methods enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString * hookMethod = [trackerMathods objectAtIndex:idx];
        [self hookTarget:target withTrackerName:trackerName method:obj trackerMathod:hookMethod];
    }];
}

- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName method:(NSString *)method trackerMathod:(NSString *)trackerMathod {
    SEL sel = NSSelectorFromString(method);
    SEL hookSel = NSSelectorFromString([NSString stringWithFormat:@"%@_%@", self.prefix, trackerMathod]);
    id tracker = [self trackerOfTarget:target byTrackerName:trackerName];
    
    if (!tracker) return;
    
    AFLogDebug(@"Hook [%@ %@] by [%@ %@]", target, NSStringFromSelector(sel), trackerName, NSStringFromSelector(hookSel));
    
#ifdef  DEBUG
    NSAssert([tracker respondsToSelector:hookSel], @"%@ not found selector: %@.", [tracker class], trackerMathod);
    NSAssert([target respondsToSelector:sel], @"%@ not found selector: %@.", [target class], method);
#endif
    
    if (![tracker respondsToSelector:hookSel] || ![target respondsToSelector:sel]){
        return;
    }
    
    AFMetricAction * action = [[AFMetricAction alloc] initActionWithBlock:^(id<AFAOPInfoProtocol> aspectInfo, AFMetricActionReplyBlock actionReplyBlock) {
        
        AFLogDebug(@"Act method [%@ %@]", tracker, NSStringFromSelector(hookSel));
        
        NSDictionary * needSentValue = nil;
        needSentValue = [tracker af_metricPerformSelector:hookSel
                                              withObjects:[aspectInfo.arguments af_metricArrayToDictWithIndex]];
        actionReplyBlock(needSentValue);
    }];
    
    #pragma clang diagnostic ignored "-Wunused-value"
    [[AFMetricTrigger alloc] initTriggerForTarget:target hookSelector:sel withOptions:AOPOptionsAfter withActions:action error:NULL];

}

#pragma mark - broadcast: one 2 N

- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName broadcastEvents:(NSArray<NSString *> *)events {
    [events enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * stop) {
        [self hookTarget:target withTrackerName:trackerName broadcastEvent:obj];
    }];
}

- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName broadcastEvent:(NSString *)event {
    SEL hookSEL = NSSelectorFromString(event);
    SEL broadcastSEL = NSSelectorFromString([NSString stringWithFormat:@"%@_%@", self.prefix, event]);
    AFMetricContainer * container = [self containerOfTrackerName:trackerName];
   
#ifdef  DEBUG
    NSAssert([target respondsToSelector:hookSEL], @"%@ not found selector: %@.", [target class], event);
    
#endif
    
    if (![container respondsToSelector:@selector(broadcastEvent:aspectsInfo:)] || ![target respondsToSelector:hookSEL]){
        return;
    }
    
    [container addBroadcastSelectors:@[NSStringFromSelector(broadcastSEL)]];
    AFMetricAction *action = [[AFMetricAction alloc] initActionWithBlock:^(id<AFAOPInfoProtocol> aspectInfo, AFMetricActionReplyBlock actionReplyBlock) {
        AFLogDebug(@"Broadcast event %@ to %@", NSStringFromSelector(hookSEL), NSStringFromClass(container.trackerClass));

        NSArray<NSDictionary *> * needSentValues = nil;
        needSentValues = [container broadcastEvent:NSStringFromSelector(broadcastSEL) aspectsInfo:aspectInfo];
        [needSentValues enumerateObjectsUsingBlock:^(NSDictionary * obj, NSUInteger idx, BOOL * stop) {
            actionReplyBlock(obj);
        }];
    }];
    
    #pragma clang diagnostic ignored "-Wunused-value"
    [[AFMetricTrigger alloc] initTriggerForTarget:target hookSelector:hookSEL withOptions:AOPOptionsAfter withActions:action error:NULL];
}

@end
