//
//  NSDictionary+AFSafe.m
//  AFFoundationKit
//
//  Created by AFuture on 2021/3/26.
//

#import "NSDictionary+AFSafe.h"

@implementation NSMutableDictionary (AFSafe)

- (void)af_safeSetObject:(id)anObject forKey:(id<NSCopying>)aKey {
    if (!aKey || !anObject) return;
    [self setObject:anObject forKey:aKey];
}

@end
