//
//  AFMetricManger.m
//  TYSmartSceneDefaultUISkin
//
//  Created by AFuture on 2021/11/3.
//

#import "AFMetricManager.h"
#import <objc/runtime.h>
#import <pthread.h>
#import "AFMetricAction.h"
#import "AFMetricTrigger.h"
#import "NSObject+AFPerformSelector.h"
#import "NSArray+AFMetric.h"
#import "AFFoundationKit.h"

static pthread_mutex_t af_metricClassContainerCacheLock;
#define Lock() pthread_mutex_lock(&af_metricClassContainerCacheLock);
#define Unlock() pthread_mutex_unlock(&af_metricClassContainerCacheLock);

@interface AFMetricManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, AFMetricContainer *> *trackerClassContainerCache;
@property (nonatomic, strong) NSMutableDictionary<NSString *, Class> *trackerClassMap;

@end

@implementation AFMetricManager {
    dispatch_queue_t _queue;
}

+ (instancetype)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _autoTrimInterval = 60;
        _queue =  dispatch_queue_create("me.afuture.metric.container", DISPATCH_QUEUE_CONCURRENT);
        _trackerClassMap = [NSMutableDictionary new];
        _trackerClassContainerCache = [NSMutableDictionary new];
        pthread_mutex_init(&af_metricClassContainerCacheLock, NULL);
        _prefix = @"tracker";
        [self _trimRecursively];
    }
    return self;
}

#pragma mark - trim

- (void)_trimRecursively {
    __weak typeof(self) _self = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_autoTrimInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        __strong typeof(_self) self = _self;
        if (!self) return;
        [self _trimInBackground];
        [self _trimRecursively];
    });
}

- (void)_trimInBackground {
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        if (!self) return;
        [self _trimEmptyContainer];
    });
}

- (NSInteger)_trimEmptyContainer {
    NSMutableArray<NSString *> *keysToTrim = [NSMutableArray new];
    Lock();
    [self.trackerClassContainerCache enumerateKeysAndObjectsUsingBlock:^(NSString * key, AFMetricContainer * obj, BOOL * stop) {
        NSArray * tmp = [obj getAllTrackers];
        if (tmp.count == 0){
            [keysToTrim addObject:key];
        }
    }];
    Unlock();
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        Lock();
        [self.trackerClassContainerCache removeObjectsForKeys:keysToTrim];
        Unlock();
    });
    AFLogDebug(@"Trim containers: %@", keysToTrim.count?keysToTrim:@"()");
    return keysToTrim.count;
}

#pragma mark - inner methods

- (Class)getTrackerClassFromName:(NSString *)trackerName {
    Class aClass = [self.trackerClassMap objectForKey:trackerName];
    if (!aClass) aClass = NSClassFromString(trackerName);
#if DEBUG
    NSAssert(aClass, @"tracker class should not be empty.");
#endif
    return aClass;
}

#pragma mark - container methods

- (NSInteger)trimContainer {
    return [self _trimEmptyContainer];
}

- (AFMetricContainer *)containerOfTrackerName:(NSString *)trackerName {
    AFMetricContainer * container = nil;
    Class trackerClass = [self getTrackerClassFromName:trackerName];
    
    if (!trackerClass) return nil;
    
    container = [self containerOfClass:trackerClass];
    return container;
}

- (AFMetricContainer *)containerOfClass:(Class)cls {
    NSString *key = NSStringFromClass(cls);
    if (![key isKindOfClass:[NSString class]] || key.length == 0) {
        return nil;
    }

    Lock();
    AFMetricContainer * container = self.trackerClassContainerCache[key];
    Unlock();

    if (!container || ![container isKindOfClass:[AFMetricContainer class]]) {
        container = nil;
        // new Instance
        container = [AFMetricContainer containerWithClass:cls];

        AFLogDebug(@"Create container %@ for %@ successed.", container, cls);

        // save to instance cache
        if (container && [container isKindOfClass:[AFMetricContainer class]]) {
            Lock();
            [self.trackerClassContainerCache af_safeSetObject:container forKey:key];
            Unlock();
        }
    }

    return container;
}

#pragma mark - tracker methods

- (id)trackerOfTarget:(id)target byTrackerName:(NSString *)trackerName {
    AFMetricContainer * container = [self containerOfTrackerName:trackerName];
    id tracker = [container trackerOfTarget:target];
    return tracker;
}

- (NSArray *)trackersByTrackerName:(NSString *)trackerName {
    AFMetricContainer * container = [self containerOfTrackerName:trackerName];
    return [container getAllTrackers];
}

#pragma mark - Public

- (void)registTracker:(Class)trackerClass {
    if (!trackerClass) {
        return;
    }
    [self.trackerClassMap af_safeSetObject:trackerClass forKey:NSStringFromClass(trackerClass)];
    AFLogDebug(@"AFMetric regist %@ successed", trackerClass);
}

@end
