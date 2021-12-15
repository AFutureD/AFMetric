//
//  AFMetircAction.m
//  AFTracker
//
//  Created by AFuture on 2021/10/29.
//

#import "AFMetricAction.h"

@interface AFMetricAction ()

@end


@implementation AFMetricAction

- (instancetype)initActionWithEventID:(NSString *)eventID
                          actionBlock:(AFMetricActionBlock)block {
    if (self = [super init]) {
        _eventID = eventID;
        _actionBlock = block;
    }
    return self;
}

- (instancetype)initActionWithBlock:(AFMetricActionBlock)block {
    if (self = [super init]) {
        _eventID = nil;
        _actionBlock = block;
    }
    return self;
}

@end
