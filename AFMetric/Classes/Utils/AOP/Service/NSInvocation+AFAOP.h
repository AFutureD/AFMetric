//
//  NSInvocation+AFAOP.h
//  AFIMPHookKit
//
//  Created by  AFuture on 2021/8/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSInvocation (AFAOP)

- (NSArray *)aop_arguments;

@end

NS_ASSUME_NONNULL_END
