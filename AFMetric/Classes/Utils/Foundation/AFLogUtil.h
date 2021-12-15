//
//  AFLogUtil.h
//  kit project
//
//  Created by ange on 2021/4/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

void AFLogFunc(NSInteger level, NSString *module, const char *file, const char *function, NSUInteger line, NSString *format, ...);

#undef TYLog
#undef AFLogDebug
#undef AFLogInfo
#undef AFLogWarn
#undef AFLogError

#define AFLog(...) \
    AFLogFunc(1, @"AFMetric", __FILE__, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define AFLogDebug(...) \
    AFLogFunc(0, @"AFMetric", __FILE__, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define AFLogInfo(...) \
    AFLogFunc(1, @"AFMetric", __FILE__, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define AFLogWarn(...) \
    AFLogFunc(2, @"AFMetric", __FILE__, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define AFLogError(...) \
    AFLogFunc(3, @"AFMetric", __FILE__, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

@interface AFLogUtil : NSObject

+ (AFLogUtil *)sharedInstance;
/// Debug mode, default is false. Verbose log will print into console if opened.
@property (nonatomic, assign) BOOL debugMode;
/// default is false.
@property (nonatomic, assign) BOOL logToLogLibrary;

@end

NS_ASSUME_NONNULL_END
