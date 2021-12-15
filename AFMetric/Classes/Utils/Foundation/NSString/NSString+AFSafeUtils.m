//
//  NSString+TYSafeUtils.m
//
//  Created by AFuture on 2021/3/17.
//

#import "NSString+AFSafeUtils.h"

@implementation NSString (AFSafeUtils)

- (long)longValue
{
    return (long)[self integerValue];
}

- (NSNumber *)numberValue
{
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    return [formatter numberFromString:self];
}

@end
