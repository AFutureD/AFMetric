//
//  AFMetricContainer.m
//  AFTracker
//
//  Created by AFuture on 2021/12/9.
//

#import "AFMetricContainer.h"
#import <objc/runtime.h>
#import <pthread.h>
#import "NSObject+AFPerformSelector.h"
#import "NSArray+AFMetric.h"
#import "NSObject+AFAOP.h"
#import "AFFoundationKit.h"

static pthread_mutex_t af_metricContainerInstanceCacheLock;

@interface AFMetricContainer ()

@property (nonatomic, strong) NSMapTable * trackerTable;

@end

@implementation AFMetricContainer

- (instancetype)initWithClass:(Class)aClass {
    if (self = [super init]) {
        _trackerClass = aClass;
        _trackerTable = [NSMapTable weakToWeakObjectsMapTable];
        pthread_mutex_init(&af_metricContainerInstanceCacheLock, NULL);
    }
    return self;
}

+ (instancetype)containerWithClass:(Class)aClass {
    return [[AFMetricContainer alloc] initWithClass:aClass];
}

- (id)trackerOfTarget:(id)target {
    if (!target) {
        return nil;
    }
    pthread_mutex_lock(&af_metricContainerInstanceCacheLock);
    id tracker = [self.trackerTable objectForKey:target];
    pthread_mutex_unlock(&af_metricContainerInstanceCacheLock);
    
    if (!tracker || ![tracker isKindOfClass:self.trackerClass]) {
        tracker = nil;
        
        tracker = [self.trackerClass new];
        
        if (tracker && [tracker isKindOfClass:self.trackerClass]) {
            pthread_mutex_lock(&af_metricContainerInstanceCacheLock);
            [self.trackerTable setObject:tracker forKey:target];
            pthread_mutex_unlock(&af_metricContainerInstanceCacheLock);
        }
        
    }
    
    return tracker;
}

- (NSArray *)getAllTrackers {
    pthread_mutex_lock(&af_metricContainerInstanceCacheLock);
    NSArray * ret = NSAllMapTableValues(self.trackerTable);
    pthread_mutex_unlock(&af_metricContainerInstanceCacheLock);
    return ret;
}

- (NSArray<NSDictionary *> *)broadcastEvent:(NSString *)selName aspectsInfo:(id<AFAOPInfoProtocol>)info {
    if (!selName || [selName length] < 0){
        return nil;
    }
    
    BOOL isSelExist = NO;
    for (NSString * obj in self.broadcastSelectorMap) {
        if ([obj isEqualToString:selName]) { isSelExist = YES; break; }
    }
    if (!isSelExist) {
        return nil;
    }
    
    SEL sel = NSSelectorFromString(selName);
    NSArray * trackers = [self getAllTrackers];
    NSMutableArray * res = [NSMutableArray new];
    
    [trackers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * stop) {
#if DEBUG
        NSCAssert([obj respondsToSelector:sel], @"%@ could not find selector: %@", [obj class], selName);
#endif
        
        NSDictionary * needSentValue = nil;
        needSentValue = [obj af_metricPerformSelector:sel
                                           withObjects:[info.arguments af_metricArrayToDictWithIndex]] ;
        [res addObject:needSentValue];
    }];
    return res;
}

- (BOOL)addBroadcastSelectors:(NSArray *)broadcastSelectors {
    if (!broadcastSelectors){
        return NO;
    }
    [self.broadcastSelectorMap addObjectsFromArray:broadcastSelectors];
    return YES;
}

- (NSMutableArray *)broadcastSelectorMap {
    if (!_broadcastSelectorMap) {
        _broadcastSelectorMap = [NSMutableArray new];
    }
    return _broadcastSelectorMap;
}

@end
