//
//  NSObject+AFAOP.m
//  AFIMPHookKit
//
//  Created by  AFuture on 2021/8/26.
//

#import "NSObject+AFAOP.h"
#import "AFAOPIdentifier.h"
#import "AFAOPManager.h"
#import "AFAOPContainer.h"
#import "AFAOPInfo.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation NSObject (AFAOP)

+ (id<AOPToken>)aop_hookSelector:(SEL)selector withOptions:(AOPOptions)options usingBlock:(id)block error:(NSError *__autoreleasing  _Nullable *)error{
    return [self add:(id)self selector:selector options:options block:block error:error];
}

- (id<AOPToken>)aop_hookSelector:(SEL)selector withOptions:(AOPOptions)options usingBlock:(id)block error:(NSError *__autoreleasing  _Nullable *)error{
    return [NSObject add:self selector:selector options:options block:block error:error];
}

+ (id)add:(NSObject *)obj selector:(SEL)selector options:(AOPOptions)option block:(id)block error:(NSError **)error{
    NSCParameterAssert(obj);
    NSCParameterAssert(selector);
    NSCParameterAssert(block);

    __block AFAOPIdentifier *identifier = nil;
    [AFAOPIdentifier lock:^{
        if([[AFAOPManager sharedInstance] isSelectorAllowedAndTrack:obj selector:selector options:option error:error]){
            AFAOPContainer *container = [[AFAOPManager sharedInstance]getContainerForObject:obj selecor:selector];
            identifier = [AFAOPIdentifier identifierWithSelector:selector object:obj options:option
                                                             block:block error:error];
            if (identifier) {
                [container addAspect:identifier withOptions:option];

                // Modify the class to allow message interception.
                [[AFAOPManager sharedInstance]prepareClassAndHookSelector:obj selector:selector error:error];
            }
        }
    }];
    return identifier;
}



@end
