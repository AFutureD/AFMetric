//
//  AFMetricManger.h
//  TYSmartSceneDefaultUISkin
//
//  Created by AFuture on 2021/11/3.
//

#import <Foundation/Foundation.h>
#import "AFMetricContainer.h"

NS_ASSUME_NONNULL_BEGIN

@interface AFMetricManager : NSObject

@property NSTimeInterval autoTrimInterval;
@property (nonatomic, copy) NSString * prefix;

+ (instancetype)sharedInstance;

- (AFMetricContainer *)containerOfTrackerName:(NSString *)trackerName;
- (AFMetricContainer *)containerOfClass:(Class)cls;
- (NSInteger)trimContainer;

- (Class)getTrackerClassFromName:(NSString *)trackerName;
- (void)registTracker:(nonnull Class)trackerClass;
- (id)trackerOfTarget:(id)target byTrackerName:(NSString *)trackerName;

@end

NS_ASSUME_NONNULL_END
