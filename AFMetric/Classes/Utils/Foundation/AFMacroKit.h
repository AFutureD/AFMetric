//
//  AFMacroKit.h
//  AFMetric
//
//  Created by 尼诺 on 2021/12/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifndef af_weakify
    #define af_weakify(object)  __weak __typeof__(object) weak##_##object = object;
#endif

#ifndef af_strongify
    #define af_strongify(object)  __typeof__(object) object = weak##_##object;
#endif

NS_ASSUME_NONNULL_END
