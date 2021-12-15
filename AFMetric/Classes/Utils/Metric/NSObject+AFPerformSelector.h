//
//  NSObject+AFPerformSelector.h
//  TYFoundationKit
//
//  Created by AFuture on 2021/10/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (AFPerformSelector)

- (id)af_metricPerformSelector:(SEL)sel;

/**
 Instead of performselector method with NSInvocation
 params_key: index of argument, begin from 0
 params_value: value of argument
 */
- (id)af_metricPerformSelector:(SEL)sel withObjects:(nullable NSDictionary<NSString *, id> *)params;

@end

NS_ASSUME_NONNULL_END
