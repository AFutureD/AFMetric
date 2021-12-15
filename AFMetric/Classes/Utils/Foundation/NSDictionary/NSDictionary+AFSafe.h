//
//  NSDictionary+AFSafe.h
//  AFFoundationKit
//
//  Created by AFuture on 2021/3/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableDictionary (AFSafe)

- (void)af_safeSetObject:(id)anObject forKey:(id<NSCopying>)aKey;

@end

NS_ASSUME_NONNULL_END
