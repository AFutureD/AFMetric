//
//  AFMetricContainer.h
//  AFTracker
//
//  Created by AFuture on 2021/12/9.
//

#import <Foundation/Foundation.h>
#import "AFMetricProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface AFMetricContainer: NSObject

@property (nonatomic, strong) NSMutableArray * broadcastSelectorMap;
@property (nonatomic, readonly, strong) Class trackerClass;

- (instancetype)initWithClass:(Class)aClass;
+ (instancetype)containerWithClass:(Class)aClass;

- (id)trackerOfTarget:(id)obj;
- (NSArray *)getAllTrackers;

- (BOOL)addBroadcastSelectors:(NSArray *)broadcastSelectors;
- (NSArray<NSDictionary *> *)broadcastEvent:(NSString *)selName aspectsInfo:(id<AFAOPInfoProtocol>)info;

@end

NS_ASSUME_NONNULL_END
