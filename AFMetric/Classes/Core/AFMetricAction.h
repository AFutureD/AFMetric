//
//  AFMetircAction.h
//  AFTracker
//
//  Created by AFuture on 2021/10/29.
//

#import <Foundation/Foundation.h>
#import <AFMetricProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface AFMetricAction : NSObject<AFMetricAction>

@property (nonatomic, strong) NSString * eventID;
@property (nonatomic, copy) AFMetricActionBlock actionBlock;

- (instancetype)initActionWithEventID:(NSString *)eventID actionBlock:(AFMetricActionBlock)block;
- (instancetype)initActionWithBlock:(AFMetricActionBlock)block;

@end

NS_ASSUME_NONNULL_END
