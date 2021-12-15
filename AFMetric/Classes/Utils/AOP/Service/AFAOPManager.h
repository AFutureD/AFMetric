//
//  AFAOPManager.h
//  AFIMPHookKit
//
//  Created by  AFuture on 2021/7/19.
//

#import <Foundation/Foundation.h>
#import "AFAOPConfig.h"

@class AFAOPInfo;

NS_ASSUME_NONNULL_BEGIN

@class AFAOPContainer;

@interface AFAOPManager : NSObject

+ (instancetype)sharedInstance;

- (NSMethodSignature *)getBlockMethodSignature:(id)block error:(NSError **)error;

- (BOOL)isCompatibleBlockSignature:(NSMethodSignature *)blockSignature object:(id)object selector:(SEL)selector error:(NSError **)error;

- (AFAOPContainer *)getContainerForObject:(NSObject *)object selecor:(SEL)selector;

- (void)cleanupHookedClassAndSelector:(NSObject *)object selector:(SEL)selector;

- (BOOL)isSelectorAllowedAndTrack:(NSObject *)object selector:(SEL)selector options:(AOPOptions)options error:(NSError **)error;

- (void)prepareClassAndHookSelector:(NSObject *)objc selector:(SEL)selector error:(NSError **)error;
@end

NS_ASSUME_NONNULL_END
