//
//  AFMetricManager+Values.h
//  AFMetricManager+Values
//
//  Created by AFuture D. on 2021/12/25.
//

#import <Foundation/Foundation.h>
#import "AFMetricManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface AFMetricManager (Values)

- (void)provideTracker:(NSString *_Nonnull)trackerName withTarget:(id)target values:(NSDictionary * _Nullable)trackValues;

@end

NS_ASSUME_NONNULL_END
