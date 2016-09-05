//
//  MFPerformanceMonitorManager.m
//  MakeFriends
//
//  Created by Vic on 25/8/2016.
//
//

#import "MFPerformanceMonitorManager.h"
#import "MFPerformanceMonitorWindow.h"
#import "MFPerformanceMonitorRootViewController.h"
#import "MFPerformanceModel.h"

#if _INTERNAL_MFPM_ENABLED

@interface MFPerformanceMonitorManager ()<MFPMWindowEventDelegate>

@property (nonatomic, strong) MFPerformanceMonitorRootViewController *rootViewController;

@end

@implementation MFPerformanceMonitorManager

+ (instancetype)sharedManager
{
    static MFPerformanceMonitorManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[MFPerformanceMonitorManager alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _isEnable = YES;
        _performanceModel = [[MFPerformanceModel alloc] init];
        
        __weak __typeof(self) weak_self = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weak_self showPerformanceMonitor];
        });
        
    }
    
    return self;
}

- (void)initAppId:(NSString *)appId
{
    [self.performanceModel initWithAppId:appId];
}

- (MFPerformanceMonitorWindow *)performanceMonitorWindow
{
    NSAssert([NSThread isMainThread], @"You must use %@ from the main thread only.", NSStringFromClass([self class]));
    
    if (!_performanceMonitorWindow) {
        _performanceMonitorWindow = [[MFPerformanceMonitorWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _performanceMonitorWindow.rootViewController = self.rootViewController;
        _performanceMonitorWindow.eventDelegate = self;
    }
    
    return _performanceMonitorWindow;
}

- (MFPerformanceMonitorRootViewController *)rootViewController
{
    if (!_rootViewController) {
        _rootViewController = [MFPerformanceMonitorRootViewController new];
    }
    
    return _rootViewController;
}

- (void)showPerformanceMonitor
{
    self.performanceMonitorWindow.hidden = NO;
}

#pragma mark - FLEXWindowEventDelegate

- (BOOL)shouldHandleTouchAtPoint:(CGPoint)pointInWindow
{
    return [self.rootViewController shouldReceiveTouchAtWindowPoint:pointInWindow];
}

@end

#endif
