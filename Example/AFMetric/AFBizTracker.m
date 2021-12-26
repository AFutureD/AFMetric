//
//  AFBizTracker.m
//  AFAutoTracker_Example
//
//  Created by 尼诺 on 2021/12/9.
//  Copyright © 2021 尼诺. All rights reserved.
//

#import "AFBizTracker.h"
#import <AFMetric/AFMetric.h>
#import "AFFoundationKit.h"


@interface AFBizTracker ()

@property (nonatomic, strong) NSString * name;

@end

@implementation AFBizTracker

- (void)tracker_bizMethod {
    AFLogDebug(@"[AFBizTracker] tracker_bizMethod");
}

- (void)tracker_bizMethodWithParam:(NSString *)params {
    AFLogDebug(@"[AFBizTracker] %@ tracker_bizMethod %@",self.name, params);
}

- (NSDictionary *)tracker_bizMethodWithParam:(NSString *)param anotherParam:(NSString *)anotherParam {
    AFLogDebug(@"[AFBizTracker] %@ bizMethodWithParam: %@ - %@",self.name, param, anotherParam);
    return @{
        AFMetricTriggerTypeTrack:@{
            
        }
    };
}

- (NSDictionary *)tracker_btnAction {
    AFLogDebug(@"[AFBizTracker] %@ genBtn happend.", self.name);
    return @{
        AFMetricTriggerTypeAssert:@{
            
        }
    };
}

- (void)dealloc {
    AFLogDebug(@"[AFBizTracker] dealloced.");
}

@end
