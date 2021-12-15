//
//  AFAOPInfo.m
//  AFIMPHookKit
//
//  Created by  AFuture on 2021/8/25.
//

#import "AFAOPInfo.h"
#import "NSInvocation+AFAOP.h"

@implementation AFAOPInfo

@synthesize arguments = _arguments;

- (id)initWithInstance:(__unsafe_unretained id)instance invocation:(NSInvocation *)invocation {
    NSCParameterAssert(instance);
    NSCParameterAssert(invocation);
    if (self = [super init]) {
        _instance = instance;
        _originalInvocation = invocation;
    }
    return self;
}

- (NSArray *)arguments {
    // Lazily evaluate arguments, boxing is expensive.
    if (!_arguments) {
        _arguments = self.originalInvocation.aop_arguments;
    }
    return _arguments;
}


@end
