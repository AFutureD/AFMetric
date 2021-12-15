//
//  NSObject+AFAOP.h
//  AFIMPHookKit
//
// Created by AFuture on 2021/10/29.

#import <Foundation/Foundation.h>
#import "AFAOPConfig.h"

@class AFAOPInfo;

NS_ASSUME_NONNULL_BEGIN

@protocol AOPToken <NSObject>

- (void)remove;

@end

@protocol AFAOPFuncHitProtocol <NSObject>

- (BOOL)isHitted:(AFAOPInfo *)info;

- (id)hittedBlock:(AFAOPInfo *)info;

@end


@interface NSObject (AFAOP)

+ (id<AOPToken>)aop_hookSelector:(SEL)selector
                           withOptions:(AOPOptions)options
                            usingBlock:(id)block
                                 error:(NSError **)error;

- (id<AOPToken>)aop_hookSelector:(SEL)selector
                      withOptions:(AOPOptions)options
                       usingBlock:(id)block
                           error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
