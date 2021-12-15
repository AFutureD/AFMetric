//
//  NSDictionary+TYSafeUtils.h
//  AFFoundationKit
//
//  Created by mile on 2021/3/17.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (TYSafeUtils)

- (id)af_safeObjectForKey:(id)key;
- (id)af_safeObjectForKey:(id)key class:(Class)aClass;

- (bool)af_boolForKey:(id)key;
- (CGFloat)af_floatForKey:(id)key;
- (NSInteger)af_integerForKey:(id)key;
- (int)af_intForKey:(id)key;
- (long)af_longForKey:(id)key;
- (NSNumber *)af_numberForKey:(id)key;
- (NSString *)af_stringForKey:(id)key;
- (NSDictionary *)af_dictionaryForKey:(id)key;
- (NSArray *)af_arrayForKey:(id)key;
- (NSMutableDictionary *)af_mutableDictionaryForKey:(id)key;
- (NSMutableArray *)af_mutableArrayForKey:(id)key;

@end

NS_ASSUME_NONNULL_END
