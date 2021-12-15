//
//  TYObjectTracker.m
//  Benchmark
//
//  Created by 尼诺 on 2021/12/11.
//  Copyright © 2021 chenwq. All rights reserved.
//

#import "AFObjectTracker.h"

@implementation AFObjectTracker

- (void)tracker_bizMethod {
    [AFObjectTracker class]; // hold the method
}

- (void)tracker_broadcastEvent {
    [AFObjectTracker class]; // hold the method
}
@end
