//
//  AFAOPContainer.h
//  AFIMPHookKit
//
//  Created by  AFuture on 2021/8/26.
//

#import <Foundation/Foundation.h>
#import "AFAOPConfig.h"

NS_ASSUME_NONNULL_BEGIN

@class AFAOPIdentifier;

@interface AFAOPContainer : NSObject

- (void)addAspect:(AFAOPIdentifier *)aspect withOptions:(AOPOptions)injectPosition;
- (BOOL)removeAspect:(id)aspect;
- (BOOL)hasAspects;
@property (atomic, copy) NSArray *beforeAspects;
@property (atomic, copy) NSArray *insteadAspects;
@property (atomic, copy) NSArray *afterAspects;
@end

@interface AspectTracker : NSObject
- (id)initWithTrackedClass:(Class)trackedClass;
@property (nonatomic, strong) Class trackedClass;
@property (nonatomic, readonly) NSString *trackedClassName;
@property (nonatomic, strong) NSMutableSet *selectorNames;
@property (nonatomic, strong) NSMutableDictionary *selectorNamesToSubclassTrackers;
- (void)addSubclassTracker:(AspectTracker *)subclassTracker hookingSelectorName:(NSString *)selectorName;
- (void)removeSubclassTracker:(AspectTracker *)subclassTracker hookingSelectorName:(NSString *)selectorName;
- (BOOL)subclassHasHookedSelectorName:(NSString *)selectorName;
- (NSSet *)subclassTrackersHookingSelectorName:(NSString *)selectorName;

@end

NS_ASSUME_NONNULL_END
