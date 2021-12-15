//
//  AFMetricManger.m
//  TYSmartSceneDefaultUISkin
//
//  Created by AFuture on 2021/11/3.
//

#import "AFMetricManger.h"
#import <objc/runtime.h>
#import <pthread.h>
#import "AFMetricAction.h"
#import "AFMetricTrigger.h"
#import <YYModel/YYModel.h>
#import "NSObject+AFPerformSelector.h"
#import "NSArray+AFMetric.h"
#import "AFFoundationKit.h"

static pthread_mutex_t af_metricClassContainerCacheLock;
#define Lock() pthread_mutex_lock(&af_metricClassContainerCacheLock);
#define Unlock() pthread_mutex_unlock(&af_metricClassContainerCacheLock);

@interface AFMetricManger ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, AFMetricContainer *> *trackerClassContainerCache;
@property (nonatomic, strong) NSMutableDictionary<NSString *, Class> *trackerClassMap;

@end

@implementation AFMetricManger {
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
        
        [self _trimRecursively];
    }
    return self;
}

#pragma mark - inner methods

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
    [self.trackerClassMap af_safeSetObject:trackerClass forKey:trackerClass];
    AFLogDebug(@"AFMetric regist %@ successed", trackerClass);
}

#pragma mark - Hook

- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName methods:(NSArray<NSString *> *)methods {
    [methods enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self hookTarget:target withTrackerName:trackerName method:obj];
    }];
}

- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName method:(NSString *)method {
    [self hookTarget:target withTrackerName:trackerName method:method trackerMathod:[method copy]];
}

- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName methods:(NSArray<NSString *> *)methods trackerMathods:(NSArray<NSString *> *)trackerMathods {
    [methods enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString * hookMethod = [trackerMathods objectAtIndex:idx];
        [self hookTarget:target withTrackerName:trackerName method:obj trackerMathod:hookMethod];
    }];
}

- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName method:(NSString *)method trackerMathod:(NSString *)trackerMathod {
    SEL sel = NSSelectorFromString(method);
    SEL hookSel = NSSelectorFromString([NSString stringWithFormat:@"tracker_%@", trackerMathod]);
    id tracker = [self trackerOfTarget:target byTrackerName:trackerName];
    
    if (!tracker) return;
    
    AFLogDebug(@"Hook [%@ %@] by [%@ %@]", target, NSStringFromSelector(sel), trackerName, NSStringFromSelector(hookSel));
    
#ifdef  DEBUG
    NSAssert([tracker respondsToSelector:hookSel], @"%@ not found selector: %@.", [tracker class], trackerMathod);
    NSAssert([target respondsToSelector:sel], @"%@ not found selector: %@.", [target class], method);
#endif
    
    if (![tracker respondsToSelector:hookSel] || ![target respondsToSelector:sel]){
        return;
    }
    
    AFMetricAction * action = [[AFMetricAction alloc] initActionWithBlock:^(id<AFAOPInfoProtocol> aspectInfo, AFMetricActionReplyBlock actionReplyBlock) {
        
        AFLogDebug(@"Act method [%@ %@]", tracker, NSStringFromSelector(hookSel));
        
        NSDictionary * needSentValue = nil;
        needSentValue = [tracker af_metricPerformSelector:hookSel
                                              withObjects:[aspectInfo.arguments af_metricArrayToDictWithIndex]];
        actionReplyBlock(needSentValue);
    }];
    
    #pragma clang diagnostic ignored "-Wunused-value"
    [[AFMetricTrigger alloc] initTriggerForTarget:target hookSelector:sel withOptions:AOPOptionsAfter withActions:action error:NULL];

}

- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName broadcastEvents:(NSArray<NSString *> *)events {
    [events enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * stop) {
        [self hookTarget:target withTrackerName:trackerName broadcastEvent:obj];
    }];
}

- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName broadcastEvent:(NSString *)event {
    SEL hookSEL = NSSelectorFromString(event);
    SEL broadcastSEL = NSSelectorFromString([NSString stringWithFormat:@"tracker_%@", event]);
    AFMetricContainer * container = [self containerOfTrackerName:trackerName];
   
#ifdef  DEBUG
    NSAssert([target respondsToSelector:hookSEL], @"%@ not found selector: %@.", [target class], event);
    
#endif
    
    if (![container respondsToSelector:@selector(broadcastEvent:aspectsInfo:)] || ![target respondsToSelector:hookSEL]){
        return;
    }
    
    [container addBroadcastSelectors:@[NSStringFromSelector(broadcastSEL)]];
    AFMetricAction *action = [[AFMetricAction alloc] initActionWithBlock:^(id<AFAOPInfoProtocol> aspectInfo, AFMetricActionReplyBlock actionReplyBlock) {
        AFLogDebug(@"Broadcast event %@ to %@", NSStringFromSelector(hookSEL), NSStringFromClass(container.trackerClass));

        NSArray<NSDictionary *> * needSentValues = nil;
        needSentValues = [container broadcastEvent:NSStringFromSelector(broadcastSEL) aspectsInfo:aspectInfo];
        [needSentValues enumerateObjectsUsingBlock:^(NSDictionary * obj, NSUInteger idx, BOOL * stop) {
            actionReplyBlock(obj);
        }];
    }];
    
    #pragma clang diagnostic ignored "-Wunused-value"
    [[AFMetricTrigger alloc] initTriggerForTarget:target hookSelector:hookSEL withOptions:AOPOptionsAfter withActions:action error:NULL];
}

#pragma mark - Utils

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

- (void)triggerEvent:(NSString *)evnetId withValues:(NSDictionary *)values {
    [[AFMetricTrigger class] sendEvent:evnetId withValues:values infos:@{} identifier:@""];
}


@end
