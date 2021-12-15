//
//  NSDictionary+AFSafeUtils.m
//  AFFoundationKit
//
//  Created by mile on 2021/3/17.
//

#import "NSDictionary+AFSafeUtils.h"
#import "NSString+AFSafeUtils.h"

@implementation NSDictionary (AFSafeUtils)

- (id)af_safeObjectForKey:(id)key
{
    if (key == nil) {
        return nil;
    }
    id value = [self objectForKey:key];
    if (value == [NSNull null]) {
        return nil;
    }
    return value;
}

- (id)af_safeObjectForKey:(id)key class:(Class)aClass
{
    id value = [self af_safeObjectForKey:key];
    if ([value isKindOfClass:aClass]) {
        return value;
    }
    return nil;
}

- (bool)af_boolForKey:(id)key
{
    id value = [self af_safeObjectForKey:key];
    if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]]) {
        return [value boolValue];
    }
    return NO;
}

- (CGFloat)af_floatForKey:(id)key
{
    id value = [self af_safeObjectForKey:key];
    if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]]) {
        return [value floatValue];
    }
    return 0;
}

- (NSInteger)af_integerForKey:(id)key
{
    id value = [self af_safeObjectForKey:key];
    if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]]) {
        return [value integerValue];
    }
    return 0;
}

- (int)af_intForKey:(id)key
{
    id value = [self af_safeObjectForKey:key];
    if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]]) {
        return [value intValue];
    }
    return 0;
}

- (long)af_longForKey:(id)key
{
    id value = [self af_safeObjectForKey:key];
    if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]]) {
        return [value longValue];
    }
    return 0;
}

- (NSNumber *)af_numberForKey:(id)key
{
    id value = [self af_safeObjectForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        return value;
    }
    if ([value respondsToSelector:@selector(numberValue)]) {
        return [value numberValue];
    }
    return nil;
}

- (NSString *)af_stringForKey:(id)key
{
    id value = [self af_safeObjectForKey:key];
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    if ([value respondsToSelector:@selector(stringValue)]) {
        return [value stringValue];
    }
    return nil;
}

- (NSArray *)af_arrayForKey:(id)key
{
    return [self af_safeObjectForKey:key class:[NSArray class]];
}

- (NSDictionary *)af_dictionaryForKey:(id)key
{
    return [self af_safeObjectForKey:key class:[NSDictionary class]];
}

- (NSMutableArray *)af_mutableArrayForKey:(id)key
{
    return [self af_safeObjectForKey:key class:[NSMutableArray class]];
}

- (NSMutableDictionary *)af_mutableDictionaryForKey:(id)key
{
    return [self af_safeObjectForKey:key class:[NSMutableDictionary class]];
}

@end
