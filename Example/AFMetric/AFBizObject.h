//
//  AFBizObject.h
//  AFAutoTracker_Example
//
//  Created by 尼诺 on 2021/12/9.
//  Copyright © 2021 尼诺. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AFBizObject : NSObject

@property (nonatomic, strong) NSString * name;

- (instancetype)initWithName:(NSString *)name;

- (void)bizMethod;
- (void)bizMethodWithParam:(NSString *)param;
- (void)bizMethodWithParam:(NSString *)param anotherParam:(NSString *)anotherParam;
@end

NS_ASSUME_NONNULL_END
