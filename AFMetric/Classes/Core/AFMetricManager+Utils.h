//
//  AFMetricManager+Utils.h
//  AFMetricManager+Utils
//
//  Created by AFuture D. on 2021/12/25.
//

#import <Foundation/Foundation.h>
#import "AFMetricManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface AFMetricManager(Utils)

- (void)triggerEvent:(NSString *)id withValues:(NSDictionary *)values;

@end

NS_ASSUME_NONNULL_END
