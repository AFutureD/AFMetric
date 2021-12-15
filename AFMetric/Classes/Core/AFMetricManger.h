//
//  AFMetricManger.h
//  TYSmartSceneDefaultUISkin
//
//  Created by AFuture on 2021/11/3.
//

#import <Foundation/Foundation.h>
#import "AFMetricContainer.h"

NS_ASSUME_NONNULL_BEGIN

@interface AFMetricManger : NSObject

@property NSTimeInterval autoTrimInterval;

+ (instancetype)sharedInstance;

- (AFMetricContainer *)containerOfTrackerName:(NSString *)trackerName;
- (AFMetricContainer *)containerOfClass:(Class)cls;
- (NSInteger)trimContainer;

- (void)registTracker:(nonnull Class)trackerClass;
- (id)trackerOfTarget:(id)target byTrackerName:(NSString *)trackerName;

- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName methods:(NSArray<NSString *> *)methods;
- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName method:(NSString *)method;

- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName methods:(NSArray<NSString *> *)methods trackerMathods:(NSArray<NSString *> *)trackerMathods;
- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName method:(NSString *)method trackerMathod:(NSString *)trackerMathod;

- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName broadcastEvent:(NSString *)event;
- (void)hookTarget:(id)target withTrackerName:(NSString *)trackerName broadcastEvents:(NSArray<NSString *> *)events;

- (void)provideTracker:(NSString *_Nonnull)trackerName withTarget:(id)target values:(NSDictionary * _Nullable)trackValues;

- (void)triggerEvent:(NSString *)id withValues:(NSDictionary *)values;
@end

NS_ASSUME_NONNULL_END
