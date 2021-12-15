//
//  NSArray+AFSafe.h
//  TYFoundationKit
//
//  Created by TuyaInc on 2018/12/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray<ObjectType> (AFSafe)

- (ObjectType)af_safeObjectAtIndex:(NSUInteger)index;

@end

@interface NSMutableArray (AFSafe)

- (void)af_safeAddObject:(id)anObject;
- (void)af_safeInsertObject:(id)anObject atIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
