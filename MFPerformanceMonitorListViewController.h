//
//  MFPerformanceMonitorListViewController.h
//  MakeFriends
//
//  Created by Vic on 15/8/16.
//
//

#import <UIKit/UIKit.h>
#import "MFPerformanceMonitor.h"

#if _INTERNAL_MFPM_ENABLED

typedef NS_ENUM(NSUInteger,MFPerformanceMonitorType) {
    MFPerformanceMonitorTypeLifeCycle = 0,
    MFPerformanceMonitorTypeSampling
};

@interface MFPerformanceMonitorListViewController : UIViewController

@property (nonatomic,assign) MFPerformanceMonitorType performanceMonitorType;

@end

#endif
