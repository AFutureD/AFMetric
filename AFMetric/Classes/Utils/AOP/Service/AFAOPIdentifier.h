//
//  AFAOPIdentifier.h
//  AFIMPHookKit
//
//  Created by  AFuture on 2021/8/25.
//

#import <Foundation/Foundation.h>
#import "AFAOPConfig.h"
#import "AFAOPInfo.h"

@interface AFAOPIdentifier : NSObject

+ (instancetype)identifierWithSelector:(SEL)selector object:(id)object options:(AOPOptions)options block:(id)block error:(NSError **)error;

- (BOOL)invokeWithInfo:(id<AFAOPInfoProtocol>)info;

@property (nonatomic, assign) SEL selector;

@property (nonatomic, strong) id block;

@property (nonatomic, strong) NSMethodSignature *blockSignature;

@property (nonatomic, weak) id object;

@property (nonatomic, assign) AOPOptions options;

+ (void)lock:(dispatch_block_t)block;

- (BOOL)remove;

@end

