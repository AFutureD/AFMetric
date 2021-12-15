//
//  AFAOPInfo.h
//  AFIMPHookKit
//
//  Created by  AFuture on 2021/8/25.
//

#import <Foundation/Foundation.h>
#import "AFAOPConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface AFAOPInfo : NSObject <AFAOPInfoProtocol>

- (id)initWithInstance:(__unsafe_unretained id)instance invocation:(NSInvocation *)invocation;

@property (nonatomic, unsafe_unretained, readonly) id instance;

@property (nonatomic, strong, readonly) NSArray *arguments;

@property (nonatomic, strong, readonly) NSInvocation *originalInvocation;

@end

NS_ASSUME_NONNULL_END
