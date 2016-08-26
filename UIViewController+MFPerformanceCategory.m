//
//  UIViewController+MFPerformanceCategory.m
//  MakeFriends
//
//  Created by Vic on 17/8/2016.
//
//

#import "UIViewController+MFPerformanceCategory.h"
#import <objc/runtime.h>
#import "MFPerformanceMonitorManager.h"
#import "MFPerformanceModel.h"
#import "MFPerformanceMonitorManager.h"

#if _INTERNAL_MFPM_ENABLED

@implementation UIViewController (MFPerformanceCategory)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [MFPerformanceMonitorManager sharedManager];
        
        [self swizzlingOriginalSelecotr:@selector(alloc) swizzledSelctor:@selector(mf_alloc) isInstanceMethod:NO];
        [self swizzlingOriginalSelecotr:@selector(viewDidLoad) swizzledSelctor:@selector(mf_viewDidLoad) isInstanceMethod:YES];
        [self swizzlingOriginalSelecotr:NSSelectorFromString(@"dealloc") swizzledSelctor:@selector(mf_dealloc) isInstanceMethod:YES];
    });
}

+ (void)swizzlingOriginalSelecotr:(SEL)originalSelector swizzledSelctor:(SEL)swizzledSelector isInstanceMethod:(BOOL)isInstanceMethod
{
    Class class = isInstanceMethod ? self : object_getClass(self);
    Method originalMethod = isInstanceMethod ? class_getInstanceMethod(class, originalSelector) : class_getClassMethod(class, originalSelector);
    Method swizzledMethod = isInstanceMethod ? class_getInstanceMethod(class, swizzledSelector) : class_getClassMethod(class, swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+ (instancetype)mf_alloc
{
    NSString *className = NSStringFromClass(self);
    [[MFPerformanceMonitorManager sharedManager].performanceModel monitorViewControllerMemory:className lifeCycle:MFMemoryMonitorLifeCycleAlloc];
        
    return [self mf_alloc];
}

- (void)mf_viewDidLoad
{
    [self mf_viewDidLoad];
    NSString *className = NSStringFromClass([self class]);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[MFPerformanceMonitorManager sharedManager].performanceModel monitorViewControllerMemory:className lifeCycle:MFMemoryMonitorLifeCycleDidload];
    });
}

- (void)mf_dealloc
{
    NSString *className = NSStringFromClass([self class]);
    [self mf_dealloc];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[MFPerformanceMonitorManager sharedManager].performanceModel monitorViewControllerMemory:className lifeCycle:MFMemoryMonitorLifeCycleDealloc];
    });
}

@end

#endif
