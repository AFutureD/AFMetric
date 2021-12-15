//
//  AFAOPIdentifier.m
//  AFIMPHookKit
//
//  Created by  AFuture on 2021/8/25.
//

#import "AFAOPIdentifier.h"
#import "AFAOPInfo.h"
#import "AFAOPContainer.h"
#import <libkern/OSAtomic.h>
#import "AFAOPManager.h"
#import "AFLogUtil.h"

@interface AFAOPIdentifier ()

@end

@implementation AFAOPIdentifier

+ (instancetype)identifierWithSelector:(SEL)selector object:(id)object options:(AOPOptions)options block:(id)block error:(NSError **)error {
    NSCParameterAssert(block);
    NSCParameterAssert(selector);
    
    NSMethodSignature *blockSignature = [[AFAOPManager sharedInstance]getBlockMethodSignature:block error:error]; // TODO: check signature compatibility, etc.
    if (![[AFAOPManager sharedInstance]isCompatibleBlockSignature:blockSignature object:object selector:selector error:error]) {
        return nil;
    }

    AFAOPIdentifier *identifier = nil;
    if (blockSignature) {
        identifier = [AFAOPIdentifier new];
        identifier.selector = selector;
        identifier.block = block;
        identifier.blockSignature = blockSignature;
        identifier.options = options;
        identifier.object = object; // weak
    }
    return identifier;
}

- (BOOL)invokeWithInfo:(id<AFAOPInfoProtocol>)info {
    NSInvocation *blockInvocation = [NSInvocation invocationWithMethodSignature:self.blockSignature];
    NSInvocation *originalInvocation = info.originalInvocation;
    NSUInteger numberOfArguments = self.blockSignature.numberOfArguments;

    // Be extra paranoid. We already check that on hook registration.
    if (numberOfArguments > originalInvocation.methodSignature.numberOfArguments) {
        AFLogDebug(@"Block has too many arguments. Not calling %@", info);
        return NO;
    }

    // The `self` of the block will be the AspectInfo. Optional.
    if (numberOfArguments > 1) {
        [blockInvocation setArgument:&info atIndex:1];
    }
    
    void *argBuf = NULL;
    for (NSUInteger idx = 2; idx < numberOfArguments; idx++) {
        const char *type = [originalInvocation.methodSignature getArgumentTypeAtIndex:idx];
        NSUInteger argSize;
        NSGetSizeAndAlignment(type, &argSize, NULL);
        
        if (!(argBuf = reallocf(argBuf, argSize))) {
            AFLogDebug(@"Failed to allocate memory for block invocation.");
            return NO;
        }
        
        [originalInvocation getArgument:argBuf atIndex:idx];
        [blockInvocation setArgument:argBuf atIndex:idx];
    }
    
    [blockInvocation invokeWithTarget:self.block];
    
    if (argBuf != NULL) {
        free(argBuf);
    }
    return YES;
}

- (void)invokeWithInfo:(id<AFAOPInfoProtocol>)info responseIndex:(NSInteger)index response:(NSData *)responseData{
    NSInvocation *blockInvocation = [NSInvocation invocationWithMethodSignature:self.blockSignature];
    NSInvocation *originalInvocation = info.originalInvocation;
    NSUInteger numberOfArguments = self.blockSignature.numberOfArguments;

    // Be extra paranoid. We already check that on hook registration.
    if (numberOfArguments > originalInvocation.methodSignature.numberOfArguments) {
        AFLogDebug(@"Block has too many arguments. Not calling %@", info);
    }

    // The `self` of the block will be the AspectInfo. Optional.
    if (numberOfArguments > 1) {
        [blockInvocation setArgument:&info atIndex:1];
    }
    
    void *argBuf = NULL;
    for (NSUInteger idx = 2; idx < numberOfArguments; idx++) {
        const char *type = [originalInvocation.methodSignature getArgumentTypeAtIndex:idx];
        NSUInteger argSize;
        NSGetSizeAndAlignment(type, &argSize, NULL);
        
        if (!(argBuf = reallocf(argBuf, argSize))) {
            AFLogDebug(@"Failed to allocate memory for block invocation.");
        }
        
        if(idx == (index+2)){
            [blockInvocation setArgument:&responseData atIndex:idx];
        }else{
            [originalInvocation getArgument:argBuf atIndex:idx];
            [blockInvocation setArgument:argBuf atIndex:idx];
        }
    }
    
    [blockInvocation invokeWithTarget:self.block];
    
    if (argBuf != NULL) {
        free(argBuf);
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, SEL:%@ object:%@ options:%tu block:%@ (#%tu args)>", self.class, self, NSStringFromSelector(self.selector), self.object, self.options, self.block, self.blockSignature.numberOfArguments];
}

- (BOOL)remove {
    return [AFAOPIdentifier removeIdentifier:self error:nil];
}

+ (BOOL)removeIdentifier:(AFAOPIdentifier *)identify error:(NSError **)error{
    NSCAssert([identify isKindOfClass:AFAOPIdentifier.class], @"Must have correct type.");

    __block BOOL success = NO;
    [self lock:(^{
        id object = identify.object; // strongify
        if (object) {
            AFAOPContainer *aspectContainer = [[AFAOPManager sharedInstance]getContainerForObject:object selecor:identify.selector];
            success = [aspectContainer removeAspect:identify];
            
            [[AFAOPManager sharedInstance]cleanupHookedClassAndSelector:object selector:identify.selector];
            // destroy token
            identify.object = nil;
            identify.block = nil;
            identify.selector = NULL;
        }else {
            NSString *errrorDesc = [NSString stringWithFormat:@"Unable to deregister hook. Object already deallocated: %@", identify];
            AFLogDebug(@"%@",errrorDesc);
        }
    })];
    return success;
}

+ (void)lock:(dispatch_block_t)block{
    static OSSpinLock aspect_lock = OS_SPINLOCK_INIT;
    OSSpinLockLock(&aspect_lock);
    block();
    OSSpinLockUnlock(&aspect_lock);
}

@end
