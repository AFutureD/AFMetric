//
//  TYSMARTBizObject.m
//  TYAutoTracker_Example
//
//  Created by 尼诺 on 2021/12/9.
//  Copyright © 2021 chenwq. All rights reserved.
//

#import "AFBizObject.h"
#import <AFMetric/AFMetric.h>

@implementation AFBizObject

- (instancetype)initWithName:(NSString *)name {
    if (self = [super init]) {
        _name = name;
        
        [[AFMetricManger sharedInstance] hookTarget:self withTrackerName:@"AFBizTracker" method:S4S(bizMethod)];
        [[AFMetricManger sharedInstance] hookTarget:self withTrackerName:@"AFBizTracker" method:S4S(bizMethodWithParam:)];
        [[AFMetricManger sharedInstance] hookTarget:self withTrackerName:@"AFBizTracker" method:S4S(bizMethodWithParam:anotherParam:)];
        [[AFMetricManger sharedInstance] provideTracker:@"AFBizTracker" withTarget:self values:@{
            @"name": self.name
        }];
    }
    return self;
}


- (void)bizMethod {
    AFLogInfo(@"%@ bizMethod",self.name);
}

- (void)bizMethodWithParam:(NSString *)param {
    AFLogInfo(@"%@ bizMethodWithParam: %@",self.name, param);
}

- (void)bizMethodWithParam:(NSString *)param anotherParam:(NSString *)anotherParam {
    AFLogInfo(@"%@ bizMethodWithParam: %@ - %@",self.name, param, anotherParam);
}

@end
