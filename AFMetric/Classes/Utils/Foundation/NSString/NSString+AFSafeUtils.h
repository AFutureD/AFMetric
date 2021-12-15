//
//  NSString+AFSafeUtils.h
//
//  Created by AFuture on 2021/3/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (AFSafeUtils)

- (long)longValue;
- (NSNumber *)numberValue;

@end

NS_ASSUME_NONNULL_END
