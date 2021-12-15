//
//  NSArray+AFMetricUtils.m
//  AFTracker
//
//  Created by AFuture on 2021/12/10.
//

#import "NSArray+AFMetric.h"
#import "NSDictionary+AFSafe.h"

@implementation NSArray (AFMetric)

- (NSDictionary *)af_metricArrayToDictWithIndex {
    
    if (!self) { return nil; }
    
    NSMutableDictionary * arguements = [NSMutableDictionary new];
    
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * stop) {
        [arguements af_safeSetObject:obj forKey:[NSString stringWithFormat:@"%ld",(long)idx]];
    }];
    
    return [arguements copy];
}

@end
