//
//  MFPerformanceMonitorManager.h
//  MakeFriends
//
//  Created by Vic on 25/8/2016.
//
//

#import <Foundation/Foundation.h>
#import "MFPerformanceMonitor.h"

#if _INTERNAL_MFPM_ENABLED

@class MFPerformanceModel;
@class MFPerformanceMonitorWindow;

@interface MFPerformanceMonitorManager : NSObject

@property (nonatomic, strong) MFPerformanceMonitorWindow *performanceMonitorWindow;
@property (nonatomic, strong, readonly) MFPerformanceModel *performanceModel;
@property (nonatomic) BOOL isEnable;

+ (instancetype)sharedManager;
- (void)initAppId:(NSString *)appId;
- (void)showPerformanceMonitor;

@end

#endif