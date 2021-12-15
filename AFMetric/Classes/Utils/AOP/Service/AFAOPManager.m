//
//  AFAOPManager.m
//  AFIMPHookKit
//
//  Created by  AFuture on 2021/7/19.
//

#import "AFAOPManager.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "AFAOPContainer.h"
#import "AFAOPTracker.h"
#import "AFAOPInfo.h"
#import "AFAOPIdentifier.h"
#import "NSObject+AFAOP.h"
#import "AFLogUtil.h"


@implementation AFAOPManager

+ (instancetype)sharedInstance {
    static id instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (NSMethodSignature *)getBlockMethodSignature:(id)block error:(NSError **)error{
    AOPBlockRef layout = (__bridge void *)block;
    if (!(layout->flags & AOPBlockFlagsHasSignature)) {
        NSString *description = [NSString stringWithFormat:@"The block %@ doesn't contain a type signature.", block];
        AFLogDebug(@"%@",description);
        return nil;
    }
    void *desc = layout->descriptor;
    desc += 2 * sizeof(unsigned long int);
    if (layout->flags & AOPBlockFlagsHasCopyDisposeHelpers) {
        desc += 2 * sizeof(void *);
    }
    if (!desc) {
        NSString *description = [NSString stringWithFormat:@"The block %@ doesn't has a type signature.", block];
        AFLogDebug(@"%@",description);
        return nil;
    }
    const char *signature = (*(const char **)desc);
    return [NSMethodSignature signatureWithObjCTypes:signature];
}

- (BOOL)isCompatibleBlockSignature:(NSMethodSignature *)blockSignature object:(id)object selector:(SEL)selector error:(NSError **)error{
    NSCParameterAssert(blockSignature);
    NSCParameterAssert(object);
    NSCParameterAssert(selector);

    BOOL signaturesMatch = YES;
    NSMethodSignature *methodSignature = [[object class] instanceMethodSignatureForSelector:selector];
    if (blockSignature.numberOfArguments > methodSignature.numberOfArguments) {
        signaturesMatch = NO;
    }else {
        if (blockSignature.numberOfArguments > 1) {
            const char *blockType = [blockSignature getArgumentTypeAtIndex:1];
            if (blockType[0] != '@') {
                signaturesMatch = NO;
            }
        }
        // Argument 0 is self/block, argument 1 is SEL or id<AOPInfo>. We start comparing at argument 2.
        // The block can have less arguments than the method, that's ok.
        if (signaturesMatch) {
            for (NSUInteger idx = 2; idx < blockSignature.numberOfArguments; idx++) {
                const char *methodType = [methodSignature getArgumentTypeAtIndex:idx];
                const char *blockType = [blockSignature getArgumentTypeAtIndex:idx];
                // Only compare parameter, not the optional type data.
                if (!methodType || !blockType || methodType[0] != blockType[0]) {
                    signaturesMatch = NO; break;
                }
            }
        }
    }

    if (!signaturesMatch) {
        NSString *description = [NSString stringWithFormat:@"Block signature %@ doesn't match %@.", blockSignature, methodSignature];
        AFLogDebug(@"%@",description);
        return NO;
    }
    return YES;
}

- (AFAOPContainer *)getContainerForObject:(NSObject *)object selecor:(SEL)selector{
    NSCParameterAssert(object);
    SEL aliasSelector = [self getAopSELForSelector:selector];
    AFAOPContainer *aspectContainer = objc_getAssociatedObject(object, aliasSelector);
    if (!aspectContainer) {
        aspectContainer = [AFAOPContainer new];
        objc_setAssociatedObject(object, aliasSelector, aspectContainer, OBJC_ASSOCIATION_RETAIN);
    }
    return aspectContainer;
}

- (AFAOPContainer *)getContainerForClass:(Class)kclass selector:(SEL)selector{
    NSCParameterAssert(kclass);
    AFAOPContainer *classContainer = nil;
    do {
        classContainer = objc_getAssociatedObject(kclass, selector);
        if (classContainer.hasAspects) break;
    }while ((kclass = class_getSuperclass(kclass)));

    return classContainer;
}

- (SEL)getAopSELForSelector:(SEL)selector{
    NSCParameterAssert(selector);
    return NSSelectorFromString([AOPMessagePrefix stringByAppendingFormat:@"_%@", NSStringFromSelector(selector)]);
}

- (void)cleanupHookedClassAndSelector:(NSObject *)object selector:(SEL)selector{
    NSCParameterAssert(object);
    NSCParameterAssert(selector);

    Class klass = object_getClass(object);
    BOOL isMetaClass = class_isMetaClass(klass);
    if (isMetaClass) {
        klass = (Class)object;
    }

    // Check if the method is marked as forwarded and undo that.
    Method targetMethod = class_getInstanceMethod(klass, selector);
    IMP targetMethodIMP = method_getImplementation(targetMethod);
    if ([self isMsgForwardIMP:targetMethodIMP]) {
        // Restore the original method implementation.
        const char *typeEncoding = method_getTypeEncoding(targetMethod);
        SEL aliasSelector = [self getAopSELForSelector:selector];
        Method originalMethod = class_getInstanceMethod(klass, aliasSelector);
        IMP originalIMP = method_getImplementation(originalMethod);
        NSCAssert(originalMethod, @"Original implementation for %@ not found %@ on %@", NSStringFromSelector(selector), NSStringFromSelector(aliasSelector), klass);

        class_replaceMethod(klass, selector, originalIMP, typeEncoding);
        AFLogDebug(@"Aspects: Removed hook for -[%@ %@].", klass, NSStringFromSelector(selector));
    }

    // Deregister global tracked selector
    [self deregisterTrackedSelector:object selector:selector];

    // Get the aspect container and check if there are any hooks remaining. Clean up if there are not.
    AFAOPContainer *container = [self getContainerForObject:object selecor:selector];
    if (!container.hasAspects) {
        // Destroy the container
        [self destroyContainerForObject:object selector:selector];

        // Figure out how the class was modified to undo the changes.
        NSString *className = NSStringFromClass(klass);
        if ([className hasSuffix:AOPSubclassSuffix]) {
            Class originalClass = NSClassFromString([className stringByReplacingOccurrencesOfString:AOPSubclassSuffix withString:@""]);
            NSCAssert(originalClass != nil, @"Original class must exist");
            object_setClass(object, originalClass);
            AFLogDebug(@"Aspects: %@ has been restored.", NSStringFromClass(originalClass));

            // We can only dispose the class pair if we can ensure that no instances exist using our subclass.
            // Since we don't globally track this, we can't ensure this - but there's also not much overhead in keeping it around.
            //objc_disposeClassPair(object.class);
        }else {
            // Class is most likely swizzled in place. Undo that.
            if (isMetaClass) {
                [self undoSwizzleClassInPlace:(Class)object];
            }else if (object.class != klass) {
                [self undoSwizzleClassInPlace:klass];
            }
        }
    }
}

- (BOOL)isSelectorAllowedAndTrack:(NSObject *)object selector:(SEL)selector options:(AOPOptions)options error:(NSError **)error{
    static NSSet *disallowedSelectorList;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        disallowedSelectorList = [NSSet setWithObjects:@"retain", @"release", @"autorelease", @"forwardInvocation:", nil];
    });

    // Check against the blacklist.
    NSString *selectorName = NSStringFromSelector(selector);
    if ([disallowedSelectorList containsObject:selectorName]) {
        NSString *errorDescription = [NSString stringWithFormat:@"Selector %@ is blacklisted.", selectorName];
        AFLogDebug(@"%@",errorDescription);
        return NO;
    }

    // Additional checks.
    AOPOptions position = options&AOPPositionFilter;
    if ([selectorName isEqualToString:@"dealloc"] && position != AOPOptionsBefore) {
        NSString *errorDesc = @"AspectPositionBefore is the only valid position when hooking dealloc.";
        AFLogDebug(@"%@",errorDesc);
        return NO;
    }

    if (![object respondsToSelector:selector] && ![object.class instancesRespondToSelector:selector]) {
        NSString *errorDesc = [NSString stringWithFormat:@"Unable to find selector -[%@ %@].", NSStringFromClass(object.class), selectorName];
        AFLogDebug(@"%@",errorDesc);
        return NO;
    }

    // Search for the current class and the class hierarchy IF we are modifying a class object
    if (class_isMetaClass(object_getClass(object))) {
        Class klass = [object class];
        NSMutableDictionary *swizzledClassesDict = [self getSwizzledClassesDict];
        Class currentClass = [object class];

        AFAOPTracker *tracker = swizzledClassesDict[currentClass];
        if ([tracker subclassHasHookedSelectorName:selectorName]) {
            NSSet *subclassTracker = [tracker subclassTrackersHookingSelectorName:selectorName];
            NSSet *subclassNames = [subclassTracker valueForKey:@"trackedClassName"];
            NSString *errorDescription = [NSString stringWithFormat:@"Error: %@ already hooked subclasses: %@. A method can only be hooked once per class hierarchy.", selectorName, subclassNames];
            AFLogDebug(@"%@",errorDescription);
            return NO;
        }

        do {
            tracker = swizzledClassesDict[currentClass];
            if ([tracker.selectorNames containsObject:selectorName]) {
                if (klass == currentClass) {
                    // Already modified and topmost!
                    return YES;
                }
                NSString *errorDescription = [NSString stringWithFormat:@"Error: %@ already hooked in %@. A method can only be hooked once per class hierarchy.", selectorName, NSStringFromClass(currentClass)];
                AFLogDebug(@"%@",errorDescription);
                return NO;
            }
        } while ((currentClass = class_getSuperclass(currentClass)));

        // Add the selector as being modified.
        currentClass = klass;
        AFAOPTracker *subclassTracker = nil;
        do {
            tracker = swizzledClassesDict[currentClass];
            if (!tracker) {
                tracker = [[AFAOPTracker alloc] initWithTrackedClass:currentClass];
                swizzledClassesDict[(id<NSCopying>)currentClass] = tracker;
            }
            if (subclassTracker) {
                [tracker addSubclassTracker:subclassTracker hookingSelectorName:selectorName];
            } else {
                [tracker.selectorNames addObject:selectorName];
            }

            // All superclasses get marked as having a subclass that is modified.
            subclassTracker = tracker;
        }while ((currentClass = class_getSuperclass(currentClass)));
    } else {
        return YES;
    }

    return YES;
}

- (BOOL)isMsgForwardIMP:(IMP)impl{
    return impl == _objc_msgForward
#if !defined(__arm64__)
    || impl == (IMP)_objc_msgForward_stret
#endif
    ;
}

- (void)deregisterTrackedSelector:(id)target selector:(SEL)selector{
    if (!class_isMetaClass(object_getClass(target))) return;

    NSMutableDictionary *swizzledClassesDict = [self getSwizzledClassesDict];;
    NSString *selectorName = NSStringFromSelector(selector);
    Class currentClass = [target class];
    AspectTracker *subclassTracker = nil;
    do {
        AspectTracker *tracker = swizzledClassesDict[currentClass];
        if (subclassTracker) {
            [tracker removeSubclassTracker:subclassTracker hookingSelectorName:selectorName];
        } else {
            [tracker.selectorNames removeObject:selectorName];
        }
        if (tracker.selectorNames.count == 0 && tracker.selectorNamesToSubclassTrackers) {
            [swizzledClassesDict removeObjectForKey:currentClass];
        }
        subclassTracker = tracker;
    }while ((currentClass = class_getSuperclass(currentClass)));

}

- (NSMutableDictionary *)getSwizzledClassesDict{
    static NSMutableDictionary *swizzledClassesDict;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        swizzledClassesDict = [NSMutableDictionary new];
    });
    return swizzledClassesDict;
}

- (void)destroyContainerForObject:(id<NSObject>)object selector:(SEL)selector{
    NSCParameterAssert(object);
    SEL aliasSelector = [self getAopSELForSelector:selector];
    objc_setAssociatedObject(object, aliasSelector, nil, OBJC_ASSOCIATION_RETAIN);
}

- (Class)swizzleClassInPlace:(Class)kclass{
    NSCParameterAssert(kclass);
    NSString *className = NSStringFromClass(kclass);
    
    __weak __typeof(&*self)weakSelf = self;
    [self modifySwizzledClasses:^(NSMutableSet *swizzledClasses) {
        if (![swizzledClasses containsObject:className]) {
            [weakSelf swizzleForwardInvocation:kclass];
            [swizzledClasses addObject:className];
        }
    }];
    return kclass;
}

- (void)undoSwizzleClassInPlace:(Class)kclass{
    NSCParameterAssert(kclass);
    NSString *className = NSStringFromClass(kclass);
    
    __weak __typeof(&*self)weakSelf = self;
    [self modifySwizzledClasses:^(NSMutableSet *swizzledClasses) {
        if ([swizzledClasses containsObject:className]) {
            [weakSelf undoSwizzleForwardInvocation:kclass];
            [swizzledClasses removeObject:className];
        }
    }];
}

- (void)swizzleForwardInvocation:(Class)kclass{
    NSCParameterAssert(kclass);
    // If there is no method, replace will act like class_addMethod.
//    Class class = object_getClass((id)self);
//    SEL hitSEL = @selector(functionHitted:selector:invocation:);
//    Method swizzledMethod = class_getInstanceMethod(class, hitSEL);
//    IMP originalImplementation = class_replaceMethod(kclass, @selector(forwardInvocation:), method_getImplementation(swizzledMethod), method_getTypeEncoding(methodNew));
//    if (originalImplementation) {
//        class_addMethod(kclass, NSSelectorFromString(AOPForwardInvocationSelectorName), originalImplementation, "v@:@");
//    }
    IMP originalImplementation = class_replaceMethod(kclass, @selector(forwardInvocation:), (IMP)__ASPECTS_ARE_BEING_CALLED__, "v@:@");
    if (originalImplementation) {
        class_addMethod(kclass, NSSelectorFromString(AOPForwardInvocationSelectorName), originalImplementation, "v@:@");
    }
    AFLogDebug(@"Aspects: %@ is now aspect aware.", NSStringFromClass(kclass));
}

- (void)undoSwizzleForwardInvocation:(Class)kclass{
    NSCParameterAssert(kclass);
    Method originalMethod = class_getInstanceMethod(kclass, NSSelectorFromString(AOPForwardInvocationSelectorName));
    Method objectMethod = class_getInstanceMethod(NSObject.class, @selector(forwardInvocation:));
    // There is no class_removeMethod, so the best we can do is to retore the original implementation, or use a dummy.
    IMP originalImplementation = method_getImplementation(originalMethod ?: objectMethod);
    class_replaceMethod(kclass, @selector(forwardInvocation:), originalImplementation, "v@:@");

    AFLogDebug(@"Aspects: %@ has been restored.", NSStringFromClass(kclass));
}

- (void)modifySwizzledClasses:(void (^)(NSMutableSet *swizzledClasses))block{
    static NSMutableSet *swizzledClasses;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        swizzledClasses = [NSMutableSet new];
    });
    @synchronized(swizzledClasses) {
        block(swizzledClasses);
    }
}

- (Class)hookClass:(NSObject *)objc error:(NSError **)error{
    NSCParameterAssert(objc);
    Class statedClass = objc.class;
    Class baseClass = object_getClass(objc);
    NSString *className = NSStringFromClass(baseClass);

    // Already subclassed
    if ([className hasSuffix:AOPSubclassSuffix]) {
        return baseClass;

        // We swizzle a class object, not a single object.
    }else if (class_isMetaClass(baseClass)) {
        return [self swizzleClassInPlace:(Class)objc];
        // Probably a KVO'ed class. Swizzle in place. Also swizzle meta classes in place.
    }else if (statedClass != baseClass) {
        return [self swizzleClassInPlace:baseClass];
    }

    // Default case. Create dynamic subclass.
    const char *subclassName = [className stringByAppendingString:AOPSubclassSuffix].UTF8String;
    Class subclass = objc_getClass(subclassName);

    if (subclass == nil) {
        subclass = objc_allocateClassPair(baseClass, subclassName, 0);
        if (subclass == nil) {
            NSString *errrorDesc = [NSString stringWithFormat:@"objc_allocateClassPair failed to allocate class %s.", subclassName];
            AFLogDebug(@"%@",errrorDesc);
            return nil;
        }
        
        [self swizzleForwardInvocation:subclass];
        [self hookGetClass:subclass statedClass:statedClass];
        [self hookGetClass:object_getClass(subclass) statedClass:statedClass];
        objc_registerClassPair(subclass);
    }

    object_setClass(objc, subclass);
    return subclass;
}

- (void)hookGetClass:(Class)class statedClass:(Class)statedClass{
    NSCParameterAssert(class);
    NSCParameterAssert(statedClass);
    Method method = class_getInstanceMethod(class, @selector(class));
    IMP newIMP = imp_implementationWithBlock(^(id objc) {
        return statedClass;
    });
    class_replaceMethod(class, @selector(class), newIMP, method_getTypeEncoding(method));
}

- (void)functionHitted:(__unsafe_unretained NSObject<AFAOPFuncHitProtocol> *)objc selector:(SEL)selector invocation:(NSInvocation *)invocation{
    NSCParameterAssert(objc);
    NSCParameterAssert(invocation);
    SEL originalSelector = invocation.selector;
    
    SEL aopSelector = [self getAopSELForSelector:invocation.selector];
    invocation.selector = aopSelector;
    AFAOPContainer *objectContainer = objc_getAssociatedObject(objc, aopSelector);
    AFAOPContainer *classContainer = [self getContainerForClass:object_getClass(objc) selector:aopSelector];
    AFAOPInfo *info = [[AFAOPInfo alloc] initWithInstance:objc invocation:invocation];
    NSArray<AFAOPIdentifier *> *aspectsToRemove = nil;
    BOOL isHit = NO;
    id block = nil;
    
    if([objc respondsToSelector:@selector(isHitted:)]){
        isHit = [objc isHitted:info];
    }
    if([objc respondsToSelector:@selector(hittedBlock)]){
        block = [objc performSelector:@selector(hittedBlock)];
    }else{
        isHit = NO;
    }
    // Before hooks.
    if (info.arguments.count>1){
        if (isHit){
            //动态装载
            AFAOPIdentifier *aspect = objectContainer.beforeAspects.firstObject;
            if (block){
                NSError *error;
                
                NSMethodSignature *blockSignature = [self getBlockMethodSignature:block error:&error]; // TODO: check signature compatibility, etc.
                if([self isCompatibleBlockSignature:blockSignature object:objc selector:aspect.selector error:&error]){
                    aspect.block = block;
                    aspect.blockSignature = blockSignature;
                }
            }
            
            [self invokeAop:classContainer.beforeAspects info:info removeList:aspectsToRemove];
            [self invokeAop:objectContainer.beforeAspects info:info removeList:aspectsToRemove];
            return;
        }
    }else{
        [self invokeAop:classContainer.beforeAspects info:info removeList:aspectsToRemove];
        [self invokeAop:objectContainer.beforeAspects info:info removeList:aspectsToRemove];
    }

    // Instead hooks.
    BOOL respondsToAlias = YES;
    if (objectContainer.insteadAspects.count || classContainer.insteadAspects.count) {
        [self invokeAop:classContainer.insteadAspects info:info removeList:aspectsToRemove];
        [self invokeAop:objectContainer.insteadAspects info:info removeList:aspectsToRemove];
    }else {
        Class klass = object_getClass(invocation.target);
        do {
            if ((respondsToAlias = [klass instancesRespondToSelector:aopSelector])) {
                [invocation invoke];
                break;
            }
        }while (!respondsToAlias && (klass = class_getSuperclass(klass)));
    }

    // After hooks.
    [self invokeAop:classContainer.afterAspects info:info removeList:aspectsToRemove];
    [self invokeAop:objectContainer.afterAspects info:info removeList:aspectsToRemove];

    // If no hooks are installed, call original implementation (usually to throw an exception)
    if (!respondsToAlias) {
        invocation.selector = originalSelector;
        SEL originalForwardInvocationSEL = NSSelectorFromString(AOPForwardInvocationSelectorName);
        if ([objc respondsToSelector:originalForwardInvocationSEL]) {
            ((void( *)(id, SEL, NSInvocation *))objc_msgSend)(objc, originalForwardInvocationSEL, invocation);
        }else {
            [objc doesNotRecognizeSelector:invocation.selector];
        }
    }

    // Remove any hooks that are queued for deregistration.
    [aspectsToRemove makeObjectsPerformSelector:@selector(remove)];
}

static void __ASPECTS_ARE_BEING_CALLED__(__unsafe_unretained NSObject<AFAOPFuncHitProtocol> *self, SEL selector, NSInvocation *invocation){
    NSCParameterAssert(self);
    NSCParameterAssert(invocation);
    SEL originalSelector = invocation.selector;
    
    SEL aopSelector = [[AFAOPManager sharedInstance] getAopSELForSelector:invocation.selector];
    invocation.selector = aopSelector;
    AFAOPContainer *objectContainer = objc_getAssociatedObject(self, aopSelector);
    AFAOPContainer *classContainer = [[AFAOPManager sharedInstance] getContainerForClass:object_getClass(self) selector:aopSelector];
    AFAOPInfo *info = [[AFAOPInfo alloc] initWithInstance:self invocation:invocation];
    NSArray<AFAOPIdentifier *> *aspectsToRemove = nil;

    BOOL isHit = NO;
    id block = nil;
    
    if([self respondsToSelector:@selector(isHitted:)]){
        isHit = [self isHitted:info];
    }
    if([self respondsToSelector:@selector(hittedBlock:)]){
        block = [self hittedBlock:info];
    }else{
        isHit = NO;
    }
    // Before hooks.
    if (info.arguments.count>1){
        if (isHit){
            //动态装载
            AFAOPIdentifier *aspect = objectContainer.beforeAspects.firstObject;
            if (block){
                NSError *error;
                
                NSMethodSignature *blockSignature = [[AFAOPManager sharedInstance] getBlockMethodSignature:block error:&error]; // TODO: check signature compatibility, etc.
                if([[AFAOPManager sharedInstance] isCompatibleBlockSignature:blockSignature object:self selector:aspect.selector error:&error]){
                    aspect.block = block;
                    aspect.blockSignature = blockSignature;
                }
            }
            
            [[AFAOPManager sharedInstance] invokeAop:classContainer.beforeAspects info:info removeList:aspectsToRemove];
            [[AFAOPManager sharedInstance] invokeAop:objectContainer.beforeAspects info:info removeList:aspectsToRemove];
            return;
        }
    }else{
        [[AFAOPManager sharedInstance] invokeAop:classContainer.beforeAspects info:info removeList:aspectsToRemove];
        [[AFAOPManager sharedInstance] invokeAop:objectContainer.beforeAspects info:info removeList:aspectsToRemove];
    }

    // Instead hooks.
    BOOL respondsToAlias = YES;
    if (objectContainer.insteadAspects.count || classContainer.insteadAspects.count) {
        [[AFAOPManager sharedInstance] invokeAop:classContainer.insteadAspects info:info removeList:aspectsToRemove];
        [[AFAOPManager sharedInstance] invokeAop:objectContainer.insteadAspects info:info removeList:aspectsToRemove];
    }else {
        Class klass = object_getClass(invocation.target);
        do {
            if ((respondsToAlias = [klass instancesRespondToSelector:aopSelector])) {
                [invocation invoke];
                break;
            }
        }while (!respondsToAlias && (klass = class_getSuperclass(klass)));
    }

    // After hooks.
    [[AFAOPManager sharedInstance] invokeAop:classContainer.afterAspects info:info removeList:aspectsToRemove];
    [[AFAOPManager sharedInstance] invokeAop:objectContainer.afterAspects info:info removeList:aspectsToRemove];

    // If no hooks are installed, call original implementation (usually to throw an exception)
    if (!respondsToAlias) {
        invocation.selector = originalSelector;
        SEL originalForwardInvocationSEL = NSSelectorFromString(AOPForwardInvocationSelectorName);
        if ([self respondsToSelector:originalForwardInvocationSEL]) {
            ((void( *)(id, SEL, NSInvocation *))objc_msgSend)(self, originalForwardInvocationSEL, invocation);
        }else {
            [self doesNotRecognizeSelector:invocation.selector];
        }
    }

    // Remove any hooks that are queued for deregistration.
    [aspectsToRemove makeObjectsPerformSelector:@selector(remove)];
}

- (void)invokeAop:(NSArray *)aops info:(AFAOPInfo *)info removeList:(NSArray *)aopsToRemove{
    for (AFAOPIdentifier *aop in aops) {
        [aop invokeWithInfo:info];
        if (aop.options & AOPOptionsAutomaticRemoval) {
            aopsToRemove = [aopsToRemove?:@[] arrayByAddingObject:aop];
        }
    }
}

- (void)prepareClassAndHookSelector:(NSObject *)objc selector:(SEL)selector error:(NSError **)error{
    NSCParameterAssert(selector);
    Class klass = [self hookClass:objc error:error];
    Method targetMethod = class_getInstanceMethod(klass, selector);
    IMP targetMethodIMP = method_getImplementation(targetMethod);

    if (![self isMsgForwardIMP:targetMethodIMP]) {
        // Make a method alias for the existing method implementation, it not already copied.
        const char *typeEncoding = method_getTypeEncoding(targetMethod);
        SEL aliasSelector = [self getAopSELForSelector:selector];
        if (![klass instancesRespondToSelector:aliasSelector]) {
            __unused BOOL addedAlias = class_addMethod(klass, aliasSelector, method_getImplementation(targetMethod), typeEncoding);
            NSCAssert(addedAlias, @"Original implementation for %@ is already copied to %@ on %@", NSStringFromSelector(selector), NSStringFromSelector(aliasSelector), klass);
        }

        // We use forwardInvocation to hook in.
        class_replaceMethod(klass, selector, [self getMsgForwardIMP:objc selector:selector], typeEncoding);
        AFLogDebug(@"Aspects: Installed hook for -[%@ %@].", klass, NSStringFromSelector(selector));
    }
}

- (IMP)getMsgForwardIMP:(NSObject *)target selector:(SEL)selector{
    IMP msgForwardIMP = _objc_msgForward;
#if !defined(__arm64__)
    // As an ugly internal runtime implementation detail in the 32bit runtime, we need to determine of the method we hook returns a struct or anything larger than id.
    // https://developer.apple.com/library/mac/documentation/DeveloperTools/Conceptual/LowLevelABI/000-Introduction/introduction.html
    // https://github.com/ReactiveCocoa/ReactiveCocoa/issues/783
    // http://infocenter.arm.com/help/topic/com.arm.doc.ihi0042e/IHI0042E_aapcs.pdf (Section 5.4)
    Method method = class_getInstanceMethod(target.class, selector);
    const char *encoding = method_getTypeEncoding(method);
    BOOL methodReturnsStructValue = encoding[0] == _C_STRUCT_B;
    if (methodReturnsStructValue) {
        @try {
            NSUInteger valueSize = 0;
            NSGetSizeAndAlignment(encoding, &valueSize, NULL);

            if (valueSize == 1 || valueSize == 2 || valueSize == 4 || valueSize == 8) {
                methodReturnsStructValue = NO;
            }
        } @catch (__unused NSException *e) {}
    }
    if (methodReturnsStructValue) {
        msgForwardIMP = (IMP)_objc_msgForward_stret;
    }
#endif
    return msgForwardIMP;
}

@end
