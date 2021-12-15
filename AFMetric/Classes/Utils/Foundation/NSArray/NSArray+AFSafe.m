//
//  NSArray+AFSafe.m
//  AFFoundationKit
//
//  Created by AFuture on 2018/12/17.
//

#import "NSArray+AFSafe.h"

@implementation NSArray (AFSafe)

- (id)af_safeObjectAtIndex:(NSUInteger)index {
    return index < self.count ? [self objectAtIndex:index] : nil;
}

@end

@implementation NSMutableArray (AFSafe)

- (void)af_safeAddObject:(id)anObject {
    if (anObject) {
        [self addObject:anObject];
    }
}

- (void)af_safeInsertObject:(id)anObject atIndex:(NSUInteger)index {
    if (!anObject || index < 0) {
        return;
    }
    if (index == self.count) {
        [self addObject:anObject];
    } else if (index < self.count) {
        [self insertObject:anObject atIndex:index];
    }
}

@end
