//
//  NSObject+TYPerformSelector.m
//  TYFoundationKit
//
//  Created by AFuture on 2021/10/29.
//

#import "NSObject+AFPerformSelector.h"

@implementation NSObject (AFPerformSelector)

- (id)af_metricPerformSelector:(SEL)sel {
    return [self af_metricPerformSelector:sel withObjects:nil];
}

- (id)af_metricPerformSelector:(SEL)sel withObjects:(nullable NSDictionary<NSString *, id> *)params {
    if (![self respondsToSelector:sel]) {
        NSString *msg = [NSString stringWithFormat:@"-[%@ %@]:unrecognized selector sent to instance", [self class], NSStringFromSelector(sel)];
        @throw [NSException exceptionWithName:@"selector not found" reason:msg userInfo:nil];
    }
    
    NSMethodSignature *sign = [self methodSignatureForSelector:sel];
    if (!sign) {
        return nil;
    }
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sign];
    if (!invocation) {
        return nil;
    }
    [invocation setTarget:self];
    [invocation setSelector:sel];
    NSArray<NSString *> *keys = params.allKeys;
    keys = [keys sortedArrayUsingComparator:^NSComparisonResult(NSString *  _Nonnull obj1, NSString *  _Nonnull obj2) {
        if (obj1.integerValue < obj2.integerValue) {
            return NSOrderedAscending;
        } else if (obj1.integerValue == obj2.integerValue) {
            return NSOrderedSame;
        } else { //!OCLint
            return NSOrderedDescending;
        }
    }];
    [keys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id value = params[obj];
        
        // 本文件专门用于 AOP 返回值的 Perform.
        // AOP 会将 nil 参数转为 NSNull，所以本方法将 NSNull 转回 nil.
        if ([value isKindOfClass:[NSNull class]]){
            value = nil;
        }
        [invocation setArgument:&value atIndex:idx+2];
    }];
    
    [invocation invoke];
    return [NSObject af_metrciGetReturnFromInv:invocation withSig:sign];
}

+ (id)af_metrciGetReturnFromInv:(NSInvocation *)inv withSig:(NSMethodSignature *)sig __attribute__((annotate("oclint:suppress"))) {
    NSUInteger length = [sig methodReturnLength];
    if (length == 0) return nil;
    
    char *type = (char *)[sig methodReturnType];
    while (*type == 'r' || // const
           *type == 'n' || // in
           *type == 'N' || // inout
           *type == 'o' || // out
           *type == 'O' || // bycopy
           *type == 'R' || // byref
           *type == 'V') { // oneway
        type++; // cutoff useless prefix
    }
    
#define return_with_number(_type_) \
do { \
_type_ ret; \
[inv getReturnValue:&ret]; \
return @(ret); \
} while (0)
    
    switch (*type) {
        case 'v': return nil; // void
        case 'B': return_with_number(bool);
        case 'c': return_with_number(char);
        case 'C': return_with_number(unsigned char);
        case 's': return_with_number(short);
        case 'S': return_with_number(unsigned short);
        case 'i': return_with_number(int);
        case 'I': return_with_number(unsigned int);
        case 'l': return_with_number(int);
        case 'L': return_with_number(unsigned int);
        case 'q': return_with_number(long long);
        case 'Q': return_with_number(unsigned long long);
        case 'f': return_with_number(float);
        case 'd': return_with_number(double);
        case 'D': { // long double
            long double ret;
            [inv getReturnValue:&ret];
            return [NSNumber numberWithDouble:ret];
        };
            
        case '@': { // id
            __unsafe_unretained id ret = nil;
            [inv getReturnValue:&ret];
            return ret;
        };
            
        case '#': { // Class
            Class ret = nil;
            [inv getReturnValue:&ret];
            return ret;
        };
            
        default: { // struct / union / SEL / void* / unknown
            const char *objCType = [sig methodReturnType];
            char *buf = calloc(1, length);
            if (!buf) return nil;
            [inv getReturnValue:buf];
            NSValue *value = [NSValue valueWithBytes:buf objCType:objCType];
            free(buf);
            return value;
        };
    }
#undef return_with_number
}

@end
