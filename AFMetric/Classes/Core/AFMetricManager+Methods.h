//
//  AFMetricManager+Hook.h
//  AFMetricManager+Hook
//
//  Created by AFuture D. on 2021/12/25.
//

#import <Foundation/Foundation.h>
#import "AFMetricManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface AFMetricManager (Methods)

- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName methods:(NSArray<NSString *> *)methods;
- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName method:(NSString *)method;

- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName methods:(NSArray<NSString *> *)methods trackerMathods:(NSArray<NSString *> *)trackerMathods;
- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName method:(NSString *)method trackerMathod:(NSString *)trackerMathod;

- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName broadcastEvent:(NSString *)event;
- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName broadcastEvents:(NSArray<NSString *> *)events;

@end

NS_ASSUME_NONNULL_END
