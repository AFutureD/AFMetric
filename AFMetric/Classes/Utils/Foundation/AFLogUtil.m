//
//  AFLogUtil.m
//  kit project
//
//  Created by AFuture on 2021/4/22.
//

#import "AFLogUtil.h"

#ifdef DEBUG
    #define NSLog(FORMAT, ...) fprintf(stderr,"%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
    #define NSLog(...) {}
#endif

void AFLogFunc(NSInteger level, NSString *module, const char *file, const char *function, NSUInteger line, NSString *format, ...) {
    
    if (!format) return;
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    
    // logToTYLogLibrary 控制日志打印的渠道，如果YES，无论debug还是release模式都需要发给日志库
    if ([AFLogUtil sharedInstance].logToLogLibrary) {
        NSMutableDictionary *logDict = [NSMutableDictionary dictionary];
        logDict[@"level"] = @(level);
        logDict[@"module"] = module ?: @"";
        logDict[@"file"] = [NSString stringWithCString:file encoding:NSUTF8StringEncoding] ?: @"";
        logDict[@"func"] = [NSString stringWithCString:function encoding:NSUTF8StringEncoding] ?: @"";
        logDict[@"line"] = @(line);
        logDict[@"isSDK"] = @(YES);
        logDict[@"message"] = message ?: @"";
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AFLogToLogLibarayNotification" object:nil userInfo:logDict];
        
    } else {

        // debugMode 控制日志是否打印
        if (![AFLogUtil sharedInstance].debugMode) {
            return;
        }
        NSString * functionName = [NSString stringWithCString:function encoding:NSUTF8StringEncoding] ?: @"";
        NSArray *arrayOfComponents = [functionName componentsSeparatedByString:@"["];
        if (arrayOfComponents.count > 0) {
            arrayOfComponents = [arrayOfComponents[1] componentsSeparatedByString:@" "];
            functionName = arrayOfComponents[0];
        }
        
        NSString * levelStr = nil;
        switch (level) {
            case 0:
                levelStr = @"DEBUG";
                break;
            case 1:
                levelStr = @"INFO ";
                break;
            case 2:
                levelStr = @"WARN ";
                break;
            case 3:
                levelStr = @"ERROR";
                break;
            default:
                levelStr = @"OTHER";
                break;
        }
        NSDate * now = [NSDate date];
        NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
        [outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *newDateString = [outputFormatter stringFromDate:now];
//        switch (level) {
//            case 0:
//                levelStr = @"DEBUG";
//                break;
//            default:
//                levelStr = @"OTHER";
//                break;
//        }
        NSLog(@"%@ <%@> [%@/%@] _ %@", newDateString, levelStr, module, functionName, message);
    }
    
}

@implementation AFLogUtil

+ (AFLogUtil *)sharedInstance {
    static AFLogUtil *utilLog = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        utilLog = [[AFLogUtil alloc] init];
    });
    return utilLog;
}

- (void)setDebugMode:(BOOL)debugMode {
    _debugMode = debugMode;
}

- (void)setLogToLogLibrary:(BOOL)logToLogLibrary {
    _logToLogLibrary = logToLogLibrary;
}

@end
