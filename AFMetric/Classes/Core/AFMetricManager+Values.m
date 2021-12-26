//
//  AFMetricManager+Values.m
//  AFMetricManager+Values
//
//  Created by AFuture D. on 2021/12/25.
//

#import "AFMetricManager+Values.h"
#import <YYModel/YYModel.h>
#import "AFFoundationKit.h"

@implementation AFMetricManager (Values)

- (void)provideTracker:(NSString * _Nonnull)trackerName withTarget:(id)target values:(NSDictionary * _Nullable)trackValues {
    id tracker = [self trackerOfTarget:target byTrackerName:trackerName];
    Class aClass = [self getTrackerClassFromName:trackerName];
    
    if (!aClass || !tracker) return;
        
    YYClassInfo * meta = [YYClassInfo classInfoWithClass:aClass];

    [trackValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL * stop) {
        YYClassPropertyInfo * propMeta = meta.propertyInfos[key];
        if (propMeta && propMeta.setter) {
            [tracker setValue:obj forKeyPath:key];
            AFLogDebug(@"%@ set value %@ for key: %@", tracker, obj, key);
        }
    }];
}

@end
