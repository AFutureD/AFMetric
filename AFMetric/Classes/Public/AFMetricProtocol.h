//
//  AFMetricProtocol.h
//  Pods
//
//  Created by AFuture on 2021/7/16.
//

#import <Foundation/Foundation.h>
#import "NSObject+AFAOP.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^AFMetricActionReplyBlock)(NSDictionary * _Nullable reply);
typedef void (^AFMetricActionBlock)(_Nullable id<AFAOPInfoProtocol> aspectInfo, AFMetricActionReplyBlock _Nullable actionReplyBlock);

@protocol AFMetricAction <NSObject>

@property (nonatomic, strong) NSString * _Nullable eventID;
@property (nonatomic, copy) AFMetricActionBlock _Nullable actionBlock;

@end

@protocol AFMetricProtocol <NSObject>

- (void)registTracker:(nonnull Class)trackerClass;

- (void)hookTarget:(id _Nonnull)target withTrackerName:(NSString * _Nonnull)trackerName methods:(NSArray<NSString *> * _Nullable)methods;
- (void)hookTarget:(id _Nonnull)target withTrackerName:(NSString * _Nonnull)trackerName method:(NSString * _Nullable)method;

- (void)hookTarget:(id _Nonnull)target withTrackerName:(NSString * _Nonnull)trackerName methods:(NSArray<NSString *> * _Nullable)methods trackerMathods:(NSArray<NSString *> * _Nullable)trackerMathods;
- (void)hookTarget:(id _Nonnull)target withTrackerName:(NSString * _Nonnull)trackerName method:(NSString * _Nullable)method trackerMathod:(NSString * _Nullable)trackerMathod;

- (void)hookTarget:(id _Nonnull)target withTrackerName:(NSString * _Nonnull)trackerName broadcastEvent:(NSString * _Nonnull)event;
- (void)hookTarget:(id _Nonnull)target withTrackerName:(NSString * _Nonnull)trackerName broadcastEvents:(NSArray<NSString *> * _Nonnull)events;

- (void)provideTracker:(NSString *_Nonnull)trackerName withValues:(NSDictionary * _Nullable)trackValues;

- (void)triggerEvent:(NSString * _Nonnull)eventId withValues:(NSDictionary * _Nonnull)trackValues;

@end

NS_ASSUME_NONNULL_END
