//
//  Header.h
//  AFIMPHookKit
//
// Created by AFuture on 2021/10/29.

#ifndef AFAOPConfig_h
#define AFAOPConfig_h

static NSString *const AOPSubclassSuffix = @"_AFAOP_";
static NSString *const AOPMessagePrefix = @"afaop_";
static NSString *const AOPForwardInvocationSelectorName = @"__afaop_forwardInvocation:";
#define AOPPositionFilter 0x07

typedef NS_OPTIONS(NSUInteger, AOPOptions) {
    AOPOptionsAfter   = 0,            /// Called after the original implementation (default)
    AOPOptionsInstead = 1,            /// Will replace the original implementation.
    AOPOptionsBefore  = 2,            /// Called before the original implementation.
    
    AOPOptionsAutomaticRemoval = 1 << 3, /// Will remove the hook after the first execution.
    AOPOptionsAutoCheck        = 4
};

// Block internals.
typedef NS_OPTIONS(int, AOPBlockFlags) {
    AOPBlockFlagsHasCopyDisposeHelpers = (1 << 25),
    AOPBlockFlagsHasSignature          = (1 << 30)
};
typedef struct _AOPBlock {
    __unused Class isa;
    AOPBlockFlags flags;
    __unused int reserved;
    void (__unused *invoke)(struct _AOPBlock *block, ...);
    struct {
        unsigned long int reserved;
        unsigned long int size;
        void (*copy)(void *dst, const void *src);
        void (*dispose)(const void *);
        const char *signature;
        const char *layout;
    } *descriptor;
    // imported variables
} *AOPBlockRef;

@protocol AFAOPInfoProtocol <NSObject>

/// The instance that is currently hooked.
- (id)instance;

/// The original invocation of the hooked method.
- (NSInvocation *)originalInvocation;

/// All method arguments, boxed. This is lazily evaluated.
- (NSArray *)arguments;

@end
#endif /* AFAOPConfig_h */
