//
//  Benchmark.m
//  Benchmark
//
//  Created by 尼诺 on 2021/12/11.
//  Copyright © 2021 chenwq. All rights reserved.
//
// Sample as below
// ==================== START BENCHMARK ====================
// .................. repeat 100000 times ..................
// ==================== BENCHMARK REGISTER =================
// Generate random class :    372.03ms
// Register Tracker class:   3127.40ms
// ==================== BENCHMARK HOOK =====================
// Perform method        :      9.58ms
// Hook method           :   1723.88ms
// Perform hooked method :   1209.24ms
// =============== BENCHMARK TRIM CONTAINER ================
// Empty containers count:      100000
// Trim empty containers :     84.22ms

#import "Benchmark.h"
#import <objc/runtime.h>
#import "AFObject.h"
#import "AFObjectTracker.h"
#import <QuartzCore/QuartzCore.h>
#import <AFMetric/AFMetric.h>

#ifdef DEBUG
    #define NSLog(FORMAT, ...) fprintf(stderr,"%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
    #define NSLog(...) {}
#endif

static int count = 100000;

@implementation Benchmark

+ (void)benchmark {
    NSLog(@"==================== START BENCHMARK ====================");
    NSLog(@".................. repeat %6d times ..................", count);
    
    [self benchmarkRegister];
    [self benchmarkHook];
    [self benchmarkTrimContainer];
}

+ (void)benchmarkRegister {
    NSLog(@"==================== BENCHMARK REGISTER =================");
    
    AFMetricManger * manager = [AFMetricManger sharedInstance];
    NSTimeInterval begin, end, time;

    begin = CACurrentMediaTime();
    @autoreleasepool {
        for (int i = 0; i < count; i++) {
            [self aRandomClass];
        }
    }
    end = CACurrentMediaTime();
    time = end - begin;
    NSLog(@"Generate random class :  %8.2fms", time * 1000); // 377.84ms
    
    
    begin = CACurrentMediaTime();
    @autoreleasepool {
        for (int i = 0; i < count; i++) {
            Class tmp = [self aRandomClass];
            [manager registTracker:tmp];
            [manager containerOfClass:tmp];
        }
    }
    end = CACurrentMediaTime();
    time = end - begin - time;
    NSLog(@"Register Tracker class:  %8.2fms", time * 1000);
    // 3073.83ms
    // registTracker: 50% - containerOfClass:50%
    
    [manager trimContainer];
}

+ (void)benchmarkHook {
    NSLog(@"==================== BENCHMARK HOOK =====================");
    AFMetricManger * manager = [AFMetricManger sharedInstance];
    NSTimeInterval begin, end, time, baseTime;
    
    begin = CACurrentMediaTime();
    @autoreleasepool {
        for (int i = 0; i < count; i++) {
            AFObject * tmp = [AFObject new];
            [tmp bizMethod];
        }
    }
    end = CACurrentMediaTime();
    baseTime = end - begin;
    NSLog(@"Perform method        :  %8.2fms", baseTime * 1000); // 10.21ms
    
    begin = CACurrentMediaTime();
    @autoreleasepool {
        for (int i = 0; i < count; i++) {
            AFObject * tmp = [AFObject new];
            [manager hookTarget:tmp withTrackerName:@"AFObjectTracker" method:S4S(bizMethod)];
        }
    }
    end = CACurrentMediaTime();
    time = end - begin - baseTime;
    NSLog(@"Hook method           :  %8.2fms", time * 1000); // 1753.71ms
    
    
    begin = CACurrentMediaTime();
    @autoreleasepool {
        for (int i = 0; i < count; i++) {
            AFObject * tmp = [AFObject new];
            [manager hookTarget:tmp withTrackerName:@"AFObjectTracker" method:S4S(bizMethod)];
            [tmp bizMethod];
        }
    }
    end = CACurrentMediaTime();
    time = end - begin - baseTime - time;
    NSLog(@"Perform hooked method :  %8.2fms", time * 1000); // 1177.45ms
    
    
    [manager trimContainer];
}

+ (void)benchmarkTrimContainer {
    NSLog(@"=============== BENCHMARK TRIM CONTAINER ================");
    
    AFMetricManger * manager = [AFMetricManger sharedInstance];
    NSTimeInterval begin, end, time;
    
    @autoreleasepool {
        for (int i = 0; i < count; i++) {
            Class tmp = [self aRandomClass];
            [manager registTracker:tmp];
            [manager containerOfClass:tmp];
        }
    }
    
    begin = CACurrentMediaTime();
    @autoreleasepool {
        NSInteger trimCount = [manager trimContainer];
        NSLog(@"Empty containers count:  %10ld",(long)trimCount);
    }
    end = CACurrentMediaTime();
    time = end - begin;
    NSLog(@"Trim empty containers :  %8.2fms", time * 1000); // 90.69ms
}

+ (void)broadcastEvent {
    [self class];
}

#pragma mark - Utils

+ (NSString *)aRandomClassName {
    return [NSUUID UUID].UUIDString;
}

+ (Class)aRandomClass {
    Class newClass = objc_allocateClassPair(self, [[self aRandomClassName] UTF8String], 0);
    objc_registerClassPair(newClass);
    return newClass;
}

@end
